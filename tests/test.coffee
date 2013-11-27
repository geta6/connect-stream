##
# Dependencies
##
fs = require 'fs'
path = require 'path'
assert = require 'assert'
request = require 'supertest'

##
# Server
##
express = require 'express'
stream = require path.resolve()
app = express()

app.set 'port', process.env.PORT || 3000
app.use stream path.resolve 'tests', 'public'
app.use app.router

app.get '/sample.txt', (req, res) ->
  res.stream '/sample.txt'

##
# Tests
##
describe 'connect-stream', ->

  _path = path.resolve 'tests', 'public', "sample.txt"
  sample =
    path: _path
    stat: fs.statSync _path
    text: fs.readFileSync _path, 'utf-8'

  # 200

  it 'should be get all text', (done) ->
    request(app)
      .get('/sample.txt')
      .expect(200)
      .expect(sample.text)
      .expect('content-encoding', 'gzip')
      .end done

  it 'should be cached contents', (done) ->
    request(app)
      .get('/sample.txt')
      .set('If-Modified-Since', sample.stat.mtime.toUTCString())
      .expect(304)
      .expect('')
      .end done

  # 206

  it 'should be get first header', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', 'bytes=0-0')
      .expect('Content-Length', '1')
      .expect(206)
      .expect(sample.text.slice(0, 1))
      .end (err, http) ->
        if http.res['content-encoding']? and http.res['content-encoding'] is 'gzip'
          return done new Error(), http
        return done err

  it 'should be get head of partial text', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', 'bytes=0-1')
      .expect('Content-Length', '2')
      .expect(206)
      .expect(sample.text.slice(0, 2))
      .end (err, http) ->
        if http.res['content-encoding']? and http.res['content-encoding'] is 'gzip'
          return done new Error(), http
        return done err

  it 'should be get first word', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', 'bytes=0-4')
      .expect('Content-Length', '5')
      .expect(206)
      .expect(sample.text.slice(0, 5))
      .end done

  it 'should be get next word', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', 'bytes=6-10')
      .expect('Content-Length', '5')
      .expect(206)
      .expect(sample.text.slice(6, 11))
      .end done

  it 'should be get all text with range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=0-#{sample.stat.size - 1}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get all text with over range request', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=0-#{sample.stat.size + 1000}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get cached partial text', (done) ->
    request(app)
      .get('/sample.txt')
      .set('If-Modified-Since', sample.stat.mtime.toUTCString())
      .set('Range', 'bytes=0-1')
      .expect(304)
      .expect('')
      .end done

  it 'should be get all text with from range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=0-")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get all text with last range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=-#{sample.stat.size}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get all text with over last range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=-#{sample.stat.size + 1000}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  # Split range

  it 'should be concatenate range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=0-5,5-10")
      .expect('Content-Length', String(11))
      .expect(206)
      .expect(sample.text.slice(0,11))
      .end done

  # 416

  it 'should be invalid with start > end range request', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=10-0")
      .expect('Content-Length', String(0))
      .expect(416)
      .expect('')
      .end done

  it 'should be invalid with over from range requet', (done) ->
    request(app)
      .get('/sample.txt')
      .set('Range', "bytes=#{sample.stat.size + 1000}-")
      .expect('Content-Length', String(0))
      .expect(416)
      .expect('')
      .end done

  # built ins

  it 'should be custom header', (done) ->
    app.get '/1/sample.txt', (req, res) ->
      res.stream '/sample.txt', headers: 'content-type': req.query.ct
    request(app)
      .get('/1/sample.txt?ct=application/octet-stream')
      .expect('content-type', 'application/octet-stream')
      .expect(200)
      .expect(sample.text)
      .end done

  it 'should be correctly detect fisrt request', (done) ->
    app.get '/2/sample.txt', (req, res) ->
      res.stream '/sample.txt', (err, range, first) ->
        return done null if first
        done new Error '!first'
    request(app)
      .get('/2/sample.txt')
      .set('Range', 'bytes=0-0')
      .end ->

  it 'should be correctly detect fisrt request', (done) ->
    app.get '/3/sample.txt', (req, res) ->
      res.stream '/sample.txt', (err, range, first) ->
        return done null if first
        done new Error '!first'
    request(app)
      .get('/3/sample.txt')
      .set('Range', 'bytes=0-1')
      .end ->

  it 'should be correctly callback', (done) ->
    app.get '/4/sample.txt', (req, res) ->
      res.stream '/sample.txt', (err, range, first) ->
        return done null if range[0] is 2 and range[1] is 6
        done new Error '!range'
    request(app)
      .get('/4/sample.txt')
      .set('Range', 'bytes=2-6')
      .end ->

  it 'should be use opt and cb simultaneous', (done) ->
    app.get '/5/sample.txt', (req, res) ->
      res.stream '/sample.txt',
        headers: 'content-type': 'application/octet-stream'
      , (err, range, first) ->
        return done null
    request(app)
      .get('/5/sample.txt')
      .expect('content-type', 'application/octet-stream')
      .expect(200)
      .end ->


