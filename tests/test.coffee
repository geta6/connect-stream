fs = require 'fs'
path = require 'path'
assert = require 'assert'
request = require 'supertest'
express = require './server/app.js'

describe 'connect-stream', ->

  _path = path.resolve 'tests', 'server', 'public', "sample.txt"
  sample =
    path: _path
    stat: fs.statSync _path
    text: fs.readFileSync _path, 'utf-8'

  # 200

  it 'should be get all text', (done) ->
    request(express)
      .get('/sample.txt')
      .expect(200)
      .expect(sample.text)
      .expect('content-encoding', 'gzip')
      .end done

  it 'should be cached contents', (done) ->
    request(express)
      .get('/sample.txt')
      .set('If-Modified-Since', sample.stat.mtime.toUTCString())
      .expect(304)
      .expect('')
      .end done

  # 206

  it 'should be get head of partial text', (done) ->
    request(express)
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
    request(express)
      .get('/sample.txt')
      .set('Range', 'bytes=0-4')
      .expect('Content-Length', '5')
      .expect(206)
      .expect(sample.text.slice(0, 5))
      .end done

  it 'should be get next word', (done) ->
    request(express)
      .get('/sample.txt')
      .set('Range', 'bytes=6-10')
      .expect('Content-Length', '5')
      .expect(206)
      .expect(sample.text.slice(6, 11))
      .end done

  it 'should be get all text with partial requesst', (done) ->
    request(express)
      .get('/sample.txt')
      .set('Range', "bytes=0-#{sample.stat.size - 1}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get all text with over partial requesst', (done) ->
    request(express)
      .get('/sample.txt')
      .set('Range', "bytes=0-#{sample.stat.size + 1000}")
      .expect('Content-Length', String(sample.stat.size))
      .expect(206)
      .expect(sample.text)
      .end done

  it 'should be get cached partial text', (done) ->
    request(express)
      .get('/sample.txt')
      .set('If-Modified-Since', sample.stat.mtime.toUTCString())
      .set('Range', 'bytes=0-1')
      .expect(304)
      .expect('')
      .end done

  # 416

  it 'should be coped with invalid range request', (done) ->
    request(express)
      .get('/sample.txt')
      .set('Range', 'bytes=2000-')
      .expect('Content-Length', String(0))
      .expect(416)
      .expect('')
      .end done

