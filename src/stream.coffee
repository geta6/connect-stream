class Stream

  fs = require 'fs'
  util = require 'util'
  path = require 'path'
  zlib = require 'zlib'
  mime = require 'mime'
  NT = require 'negotiator'
  AC = require 'async-cache'
  FD = require 'fd'

  path: no
  url: no
  opt: {}

  none:
    max: 1
    maxSize: 0
    length: -> Infinity

  noneCacheOptions:
    fd: @none
    stat: @none
    index: @none
    readdir: @none
    content: @none

  cacheOptions:
    fd: max: 1000, maxAge: 1000 * 60 * 60
    stat: max: 5000, maxAge: 1000 * 60
    content: max: 1024 * 1024 * 64, maxAge: 1000 * 60 * 10, length: (n) -> n.length
    index: max: 1024 * 8, maxAge: 1000 * 60 * 10, length: (n) -> n.length
    readdir: max: 1000, maxAge: 1000 * 60 * 10, length: (n) -> n.length

  # とちゅう
  setCahceOptions: ->
    opt = @opt.cache
    set = (key) ->
      return @none if opt[key] is no
      return util._extend util._extend({}, @cacheOptions[key]), opt[key]
    if opt is no
      opt = @none

  constructor: (opt) ->
    if typeof opt is 'string'
      @path = opt
      opt = arguments[1]
      if typeof opt is 'string'
        @url = opt
        opt = arguments[2]
    opt = util._extend {}, (opt || {})
    @path = opt.path unless @path
    throw new Error 'no path specified' if typeof p isnt 'string'
    @path = path.resolve @path
    @url = opt.url unless @url
    @url = '' unless @url
    @url = "/#{@url}" if '/' isnt @url.charAt 0
    opt.url = @url
    opt.path = @path
    @opt = opt


  cachecheck: (req, res, stats) ->
    mtime = stats.mtime.toUTCString()
    since = (new Date req.headers['if-modified-since']).toUTCString()
    res.setHeader 'Last-Modified', mtime
    return yes if since >= mtime

    etags = "\"#{stats.dev}-#{stats.ino}-#{mtime}\""
    match = req.headers['if-none-match']
    res.setHeader 'ETag', etags
    return yes if etags is match

    range = req.headers['If-Range']
    return yes if mtime is (new Date range).toUTCString()
    return yes if etags is range

    return no


  rangeParser: (req, res, stats) ->
    size = stats.size
    if req.headers?.range?
      res.statusCode = 206
      [ini, end] = req.headers.range.replace('bytes=', '').split('-').map (n) -> parseInt n, 10
      end = size - 1 if (isNaN end) or (end is 0)
      res.setHeader 'Content-Length', end + 1 - ini
      res.setHeader 'Content-Range', "bytes #{ini}-#{end}/#{size}"
      res.setHeader 'Accept-Range', 'bytes'
      res.setHeader 'Transfer-Encoding', 'chunked'
      return [ini, end]
    else
      res.statusCode = 200
      res.setHeader 'Content-Length', size
      return [0, size - 1]


  interface: (req, res, src, opts...) ->
    options = {}
    callback = ->
    while opts.shift()
      options = opt if typeof opt is 'object'
      callback = opt if typeof opt is 'function'
    options.headers or= {}
    src = path.join @path, src
    fs.stat src, (err, stats) =>
      if err
        callback err, 0, 0
        res.statusCode = 500
        return next err
      if @cachecheck req, res, stats
        callback null, 0, 1
        res.statusCode = 304
        return res.end()
      options.headers['Cache-Control'] or= 'public'
      options.headers['Content-Type'] or= mime.lookup src
      res.setHeader(key, value) for key, value of options.headers
      [start, end] = @rangeParser req, res, stats
      if start > end or stats.size < start
        res.statusCode = 416
        start = 0
        end = stats.size - 1
        res.setHeader 'Content-Length', end + 1 - start
        res.setHeader 'Content-Range', "#{start}-#{end}/#{stats.size}"
      stream = fs.createReadStream src, { start: start, end: end }
      stream.on 'close', ->
        callback null, start, end
      stream.on 'error', (err) ->
        console.error '>', err
        callback err, start, end
      return stream.pipe res


module.exports = (opts...) ->
  return (req, res, next) ->
    stream = new Stream opts
    res.stream = (src, opts...) ->
      stream.interface req, res, src, opts
    return next()
