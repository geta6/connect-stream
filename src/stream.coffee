# modules

module.exports = (req, res, next) ->

  fs = require 'fs'
  path = require 'path'
  mime = require 'mime'

  options =
    headers: {}
    complete: ->

  stream = (src, opt) ->
    options.complete = opt if typeof opt is 'function'
    if typeof opt is 'object'
      options.headers = opt.headers if opt.headers?
      options.complete = opt.complete if opt.complete?
    req.route or= {}
    req.route.path or= 'Stream'
    try
      src = (path.join options.path, src) if '/' isnt src.substr 0,1
      throw new Error 'ENOEXISTS' unless fs.existsSync src
      fstat = fs.statSync src
      throw new Error 'ENOTFILE' unless fstat.isFile()
      mtime = fstat.mtime.getTime()
      since = (new Date req.headers['if-modified-since']).getTime()
      if since >= mtime
        options.complete null, [0, 1], src
        res.statusCode = 304
        return res.end()
      etags = "\"#{fstat.dev}-#{fstat.ino}-#{mtime}\""
      match = req.headers['if-none-match']
      if etags is match
        options.complete null, [0, 1], src
        res.statusCode = 304
        return res.end()
      options.headers['Cache-Control'] or= 'public'
      options.headers['Content-Type'] or= mime.lookup src
      options.headers['Last-Modified'] or= fstat.mtime.toUTCString()
      options.headers['ETag'] or= etags
      unless req.headers.range
        res.statusCode = 200
        [ini, end] = [0, fstat.size]
        options.headers['Content-Length'] = fstat.size
      else
        res.statusCode = 206
        total = fstat.size
        [ini, end] = ((parseInt n, 10) for n in (req.headers.range.replace 'bytes=', '').split '-')
        end = total - 1 if (isNaN end) or (end is 0)
        options.headers['Content-Length'] = end + 1 - ini
        options.headers['Content-Range'] = "bytes #{ini}-#{end}/#{total}"
        options.headers['Accept-Range'] = 'bytes'
        options.headers['Transfer-Encoding'] or= 'chunked'
      for key, value of options.headers
        res.setHeader key, value
      readstream = fs.createReadStream src, { start: ini, end: end }
      readstream.on 'end', ->
        return options.complete null, [ini, end], src
      readstream.on 'error', (err) ->
        throw "ERRSTREAM #{src} #{ini}-#{end} #{err.stack || err.message}"
      return readstream.pipe res
    catch e
      options.complete e, [0, 0], src
      res.statusCode = 500
      return next new Error "#{e}: #{src} (#{req.url})"
  res.stream = stream
  return next()
