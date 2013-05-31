fs = require 'fs'
path = require 'path'
mime = require 'mime'

module.exports = (req, res, next) ->

  res.stream = (src, headers = {}, failure) ->
    failure = headers if typeof headers is 'function'
    failure or= ->
      res.writeHead 404
      res.end()

    src = path.resolve src if '/' isnt src.substr 0, 1
    return failure() unless fs.existsSync src

    stat = fs.statSync src

    if (String req.headers['if-modified-since']) is (String stat.mtime)
      res.writeHead 304
      return res.end()

    headers['Content-Type'] or= mime.lookup src
    headers['Last-Modified'] or= stat.mtime

    if stat.size is 0
      return failure()

    else if !req.headers.range
      headers['Content-Length'] or= stat.size
      res.writeHead 200, headers

      stream = fs.createReadStream src
      stream.on 'open', -> stream.pipe res

    else
      total = stat.size
      [ini, end] = for n in (req.headers.range.replace 'bytes=', '').split '-'
        parseInt n, 10
      end = total - 1 if (isNaN end) or (end is 0)
      headers['Connection'] or= 'close'
      headers['Cache-Control'] or= 'private'
      headers['Content-Length'] = end + 1 - ini
      headers['Content-Range'] = "bytes #{ini}-#{end}/#{total}"
      headers['Accept-Range'] = 'bytes'
      headers['Transfer-Encoding'] or= 'chunked'
      res.writeHead 206, headers
      stream = fs.createReadStream src, { start: ini, end: end }
      stream.on 'open', -> stream.pipe res

    stream.on 'error', ->
      return failure()

    stream.on 'end', ->
      #console.log process.memoryUsage()
      stream.destroy()
      stream = null
      return res.end()

  return next()
