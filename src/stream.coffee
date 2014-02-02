module.exports = (root, opts) ->
  stream = new Stream root, opts
  return (req, res, next) ->
    res.stream = (src, opt = {}, cb = ->) ->
      cb = opt if typeof opt is 'function'
      stream.serve src, opt, cb, req, res, next
    return next()

class Stream

  fs = require 'fs'
  url = require 'url'
  path = require 'path'
  http = require 'http'
  zlib = require 'zlib'
  mime = require 'mime'
  Negotiator = require 'negotiator'
  asyncCache = require 'async-cache'

  opts:
    root: process.cwd()
    trim: yes
    concatenate: 'join' # resolve
    passthrough: no
    cache:
      fd:
        max: 1000
        maxAge: 1000 * 60 * 60
      stat:
        max: 5000
        maxAge: 1000 * 60
      content:
        max: 1024 * 1024 * 64
        maxAge: 1000 * 60 * 10

  fdman: (require 'fd')()

  store:
    fd: null
    stat: null
    content: null

  constructor: (root = '/', opts = {}) ->

    @opts.root = root if root

    if opts.concatenate? and opts.concatenate in ['join', 'resolve']
      @opts.concatenate = opts.concatenate
    if opts.passthrough?
      @opts.passthrough = opts.passthrough

    @opts.debug = opts.debug if opts.debug?

    if opts.cache?.fd?.max?
      @opts.cache.fd.max = opts.cache.fd.max
    if opts.cache?.fd?.maxAge?
      @opts.cache.fd.maxAge = opts.cache.fd.maxAge
    if opts.cache?.stat?.max?
      @opts.cache.stat.max = opts.cache.stat.max
    if opts.cache?.stat?.maxAge?
      @opts.cache.stat.maxAge = opts.cache.stat.maxAge
    if opts.cache?.content?.max?
      @opts.cache.content.max = opts.cache.content.max
    if opts.cache?.content?.maxAge?
      @opts.cache.content.maxAge = opts.cache.content.maxAge

    if opts.cache is no
      @opts.cache.fd.max = 1
      @opts.cache.fd.maxAge = 0
      @opts.cache.fd.length = -> Infinity
      @opts.cache.stat.max = 1
      @opts.cache.stat.maxAge = 0
      @opts.cache.stat.length = -> Infinity
      @opts.cache.content.max = 1
      @opts.cache.content.maxAge = 0
      @opts.cache.content.length = -> Infinity
    else
      @opts.cache.fd.length = (n) -> n.length
      @opts.cache.stat.length = (n) -> n.length
      @opts.cache.content.length = (n) -> n.length

    @store.fd = asyncCache
      max: @opts.cache.fd.max
      maxAge: @opts.cache.fd.maxAge
      length: @opts.cache.fd.length
      load: @fdman.open.bind @fdman
      dispose: @fdman.close.bind @fdman
    @store.stat = asyncCache
      max: @opts.cache.stat.max
      maxAge: @opts.cache.stat.maxAge
      length: @opts.cache.stat.length
      load: (key, cb) =>
        return fs.stat key, cb unless (fdp = key.match /^(\d+):(.*)/)
        [fd, p] = [+fdp[1], fdp[2]]
        fs.fstat fd, (err, stat) =>
          return cb err if err
          @store.stat.set p, stat
          return cb null, stat
    @store.content = asyncCache
      max: @opts.cache.content.max
      maxAge: @opts.cache.content.maxAge
      length: @opts.cache.content.length
      load: ->
        throw new Error('This should not ever happen')

  parseRange: (stat, req) ->
    if req.headers?.range?
      ranges = []
      for range in req.headers.range.replace('bytes=', '').split(',')
        [ini, end] = range.split('-')
        if ini.length is 0
          ini = stat.size - end
          ini = 0 if ini < 0
          end = stat.size - 1
        if end.length is 0
          end = stat.size - 1
        [ini, end] = [+ini, +end]
        ranges.push { ini: ini, end: end }
      return ranges
    return null

  isAcceptGzip: (src, req) ->
    gz = false
    unless /\.t?gz$/.exec src
      neg = req.negotiator || new Negotiator req
      gz = neg.preferredEncoding(['gzip', 'identity']) is 'gzip'
    return gz

  isValidRange: (ini, end) ->
    return no if ini > end
    return yes

  error: (err, res, next, fdend) ->
    fdend() if fdend
    if typeof err is 'number'
      res.statusCode = err
    else
      res.statusCode = switch err.code
        when 'ENOENT', 'EISDIR' then 404
        when 'EPERM', 'EACCES' then 403
        else 500
    return next() if @opts.passthrough and res.statusCode is 404
    return next err

  cache: (res, fdend) ->
    fdend()
    res.statusCode = 304
    return res.end()

  serve: (src, opt, cb, req, res, next) ->

    unless src
      throw new Error '`src` should not be blank, res.stream(src, callback).'

    if typeof cb isnt 'function'
      console.error '`callback` should be function, res.stream(src, callback).'
      cb = ->

    src = path[@opts.concatenate] @opts.root, src
    src = decodeURIComponent url.parse(src).pathname if @opts.trim

    return next() unless src

    @store.fd.get src, (err, fd) =>
      if err
        cb err, null
        return @error err, res, next
      @fdman.checkout src, fd
      fdend = @fdman.checkinfn src, fd

      @store.stat.get "#{fd}:#{src}", (err, stat) =>
        if err
          cb err, null
          return @error err, res, next, fdend

        ranges = @parseRange stat, req

        if ranges is null
          partial = no
          [ini, end] = [0, stat.size - 1]
          isFirstStream = yes
        else
          unless ranges.length is 1
            console.error 'not supported multi range-spec'
          range = ranges[0]
          partial = yes
          [ini, end] = [range.ini, range.end]
          isFirstStream = (ini is 0 and end in [0, 1])

        unless @isValidRange ini, end
          res.statusCode = 416
          res.setHeader 'content-length', 0
          cb (new Error 'out of range'), [ini, end], isFirstStream
          return res.end()

        if (since = req.headers['if-modified-since'])
          since = (new Date since).getTime()
          if since && since >= stat.mtime.getTime()
            cb null, [ini, end], isFirstStream
            return @cache res, fdend

        etag = "\"#{stat.dev}-#{stat.ino}-#{stat.mtime.getTime()}\""
        if (match = req.headers['if-none-match'])
          if match is etag
            cb null, [ini, end], isFirstStream
            return @cache res, fdend
        if (match = req.headers['if-range'])
          if match is etag
            cb null, [ini, end], isFirstStream
            return @cache res, fdend

        if stat.isDirectory()
          err = new Error
          err.code = 'EISDIR'
          cb err, [ini, end], isFirstStream
          return @error err, res, next, fdend

        cache = opt.headers?['cache-control'] || 'public'
        ctype = opt.headers?['content-type'] || mime.lookup path.extname src

        res.setHeader 'cache-control', cache
        res.setHeader 'last-modified', stat.mtime.toUTCString()
        res.setHeader 'etag', etag
        res.setHeader 'content-type', ctype

        unless partial
          res.statusCode = 200
        else
          res.statusCode = 206
          end = stat.size - 1 if stat.size < end - ini + 1
          res.setHeader 'content-range', "bytes #{ini}-#{end}/#{stat.size}"

        storekey = "#{fd}:#{stat.size}:#{etag}"

        if !partial and @store.content.has storekey
          @store.content.get storekey, (err, content) =>
            fdend()
            if err
              cb err, [ini, end], isFirstStream
              return @error err, res, next
            if @isAcceptGzip(src, req) and content.gz
              res.setHeader 'content-encoding', 'gzip'
              res.setHeader 'content-length', content.gz.length
              cb null, [ini, end], isFirstStream
              return res.end content.gz
            else
              res.setHeader 'content-length', content.length
              cb null, [ini, end], isFirstStream
              return res.end content

        else
          stream = fs.createReadStream src, { fd: fd, start: ini, end: end }
          stream.destroy = ->

          stream.on 'error', (err) =>
            err = err.stack || err.message
            console.error 'Error serving %s fd=%d\n%s', src, fd, err
            res.socket.destroy()
            return fdend()

          gzstream = zlib.createGzip()

          if !partial and @isAcceptGzip src, req
            res.setHeader 'content-encoding', 'gzip'
            stream.pipe gzstream
            gzstream.pipe res
            if @store.content._cache.max > stat.size
              buf = []
              gzbuf = []
              stream.on 'data', (chunk) ->
                buf.push chunk
              gzstream.on 'data', (chunk) ->
                gzbuf.push chunk
              gzstream.on 'end', =>
                content = Buffer.concat buf
                content.gz = Buffer.concat gzbuf
                @store.content.set storekey, content
          else
            res.setHeader 'content-length', end - ini + 1
            stream.pipe res

          stream.on 'end', ->
            cb null, [ini, end], isFirstStream
            process.nextTick fdend
