# modules

fs = require 'fs'
st = require 'st'
path = require 'path'
mime = require 'mime'

module.exports = (options = {}) ->

  options.static or= yes
  options.url or= '/'
  options.path or= path.resolve 'public'
  options.index or= no
  options.passthrough or= yes

  mount = st options

  return (req, res, next) ->

    defaults =
      complete: (err, ini, end) ->

    res.stream = (src, args...) ->
      throw new Error 'NOSOURCE' unless src
      res.end() if req.method.toUpperCase() is 'HEAD'

      streams = {}
      streams.complete or= defaults.complete
      streams.headers or= {}
      streams.debug or= no

      for arg in args
        if typeof arg is 'function'
          streams.complete = arg
        else if typeof arg is 'object'
          if arg.headers
            streams.headers = arg.headers
          if arg.debug
            sterams.debug = arg.debug
          if arg.complete and typeof arg.complete is 'function'
            sterams.complete = arg.complete

      src = (path.join options.path, src) if '/' isnt src.substr 0, 1

      mount._this.cache.fd.get src, (err, fd) ->
        if err
          streams.complete err, 0, 0
          res.writeHead 404, 'Content-Type': 'text/plain'
          return res.end "Cannot Stream #{req.url}"

        mount._this.fdman.checkout src, fd
        fdend = mount._this.fdman.checkinfn src, fd
        success = (ini, end) ->
          streams.complete null, ini, end
          return fdend()
        failure = (err) ->
          streams.complete err, 0, 0
          res.writeHead 404, 'Content-Type': 'text/plain'
          res.end "Cannot Stream #{req.url}"
          return fdend()

        mount._this.cache.stat.get "#{fd}:#{src}", (err, stat) ->
          return failure err if err
          return failure (new Error 'ISDIR') if stat.isDirectory()

          mtime = stat.mtime.getTime()
          if (ims = req.headers['if-modified-since'])
            ims = new Date(ims).getTime()
            if ims >= mtime
              res.statusCode = 304
              res.end()
              return success 0, 1
          etag = "\"#{stat.dev}-#{stat.ino}-#{mtime}\""
          if etag is req.headers['if-none-match']
            res.statusCode = 304
            res.end()
            return success 0, 1

          streams.headers['Cache-Control'] or= 'public'
          streams.headers['Content-Type'] or= mime.lookup src
          streams.headers['Last-Modified'] or= stat.mtime.toUTCString()
          streams.headers['ETag'] or= etag

          unless req.headers.range
            [ini, end] = [0, stat.size]
            streams.headers['Content-Length'] = stat.size
            res.writeHead 200, streams.headers

          else
            total = stat.size
            [ini, end] = for n in (req.headers.range.replace 'bytes=', '').split '-'
              parseInt n, 10
            end = total - 1 if (isNaN end) or (end is 0)
            streams.headers['Content-Length'] = end + 1 - ini
            streams.headers['Content-Range'] = "bytes #{ini}-#{end}/#{total}"
            streams.headers['Accept-Range'] = 'bytes'
            streams.headers['Transfer-Encoding'] or= 'chunked'
            res.writeHead 206, streams.headers

          readStream = fs.createReadStream src, { fd: fd, start: ini, end: end }
          readStream.destroy = ->
          readStream.on 'end', ->
            process.nextTick ->
              if streams.debug
                console.warn 'Streaming %s fd=%d\n', src, fd, process.memoryUsage()
              return success ini, end
          readStream.on 'error', (err) ->
            console.error 'Error serving %s fd=%d\n%s', src, fd, err.stack || err.message
            return failure err
          readStream.pipe res
    # url = decodeURI req.url
    # if cacheOptions.static and url isnt '/'
    #   return stream src, {} if fs.existsSync (src = path.join cacheOptions.path, url)
    if options.static
      return if mount req, res, next
    return next()
