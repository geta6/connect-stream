# modules

fs = require 'fs'
# zlib = require 'zlib'
path = require 'path'

_ = require 'underscore'

AC = require 'async-cache'
FD = (require 'fd')()
mime = require 'mime'

defaultCacheOptions =
  path: path.resolve 'public'
  static: yes
  fd:
    max: 1000
    maxAge: 1000 * 60 * 60
  stat:
    max: 5000
    maxAge: 1000 * 60

module.exports = (cacheOptions = {}) ->
  cacheOptions = _.defaults cacheOptions, defaultCacheOptions
  cacheOptions.path = (path.resolve cacheOptions.path) if '/' isnt cacheOptions.path.substr 0, 1
  cache =
    fd: AC _.extend cacheOptions.fd,
      load: FD.open.bind FD
      dispose: FD.close.bind FD
    stat: AC _.extend cacheOptions.stat,
      load: (addr, done) -> fs.stat addr, done

  return (req, res, next) ->
    defaultSuccessFunction = ->
    defaultFailureFunction = ->
      res.writeHead 404, 'Content-Type': 'text/plain'
      return res.end "Cannot #{req.method.toUpperCase()} #{req.url}"

    stream = res.stream = (src, streamOptions = {}) ->
      streamOptions.success or= defaultSuccessFunction
      streamOptions.failure or= defaultFailureFunction
      streamOptions.headers or= {}
      src = (path.join cacheOptions.path, src) if '/' isnt src.substr 0, 1

      cache.stat.get src, (err, stat) ->
        return (streamOptions.failure err, stat, [0, 1]) if err or !stat.isFile()

        modified = stat.mtime.toUTCString()
        if (String req.headers['if-modified-since']) is modified
          res.statusCode = 304
          streamOptions.success null, stat, [0, 1]
          return res.end()

        streamOptions.headers['Cache-Control'] or= "public"
        streamOptions.headers['Content-Type'] or= mime.lookup src
        streamOptions.headers['Last-Modified'] or= modified
        streamOptions.headers['ETag'] or= "\"#{stat.dev}-#{stat.ino}-#{stat.mtime.getTime()}\""

        cache.fd.get src, (err, fd) ->
          checkIn = FD.checkinfn src, fd
          FD.checkout src, fd

          unless req.headers.range
            [ini, end] = [0, stat.size]
            streamOptions.headers['Content-Length'] = stat.size
            res.writeHead 200, streamOptions.headers

          else
            total = stat.size
            [ini, end] = for n in (req.headers.range.replace 'bytes=', '').split '-'
              parseInt n, 10
            end = total - 1 if (isNaN end) or (end is 0)
            streamOptions.headers['Content-Length'] = end + 1 - ini
            streamOptions.headers['Content-Range'] = "bytes #{ini}-#{end}/#{total}"
            streamOptions.headers['Accept-Range'] = 'bytes'
            streamOptions.headers['Transfer-Encoding'] or= 'chunked'
            res.writeHead 206, streamOptions.headers

          console.log streamOptions.headers
          readStream = fs.createReadStream src, { fd: fd, start: ini, end: end }
          readStream.destroy = ->
          readStream.on 'end', ->
            streamOptions.success null, stat, [ini, end]
            checkIn.apply @, arguments
          readStream.on 'error', (err) ->
            streamOptions.failure err, stat, [ini, end]
            checkIn.apply @, arguments
          readStream.pipe res

    if cacheOptions.static and req.url isnt '/'
      return stream src, {} if fs.existsSync (src = path.join cacheOptions.path, req.url)
    return next()
