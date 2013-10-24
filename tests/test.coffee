fs = require 'fs'
path = require 'path'
assert = require 'assert'
request = require 'supertest'
express = require './server/app.js'

describe 'connect-stream', ->

  sample = (index = 1) ->
    _path = path.resolve 'tests', 'server', 'public', "sample#{index}.txt"
    path: _path
    stat: fs.statSync _path
    text: fs.readFileSync _path, 'utf-8'

  # 200

  it 'should be get all text', (done) ->
    request(express)
      .get('/?index=1')
      .expect('Content-Length', String(sample(1).stat.size))
      .expect(200)
      .expect(sample(1).text)
      .end done

  it 'should be cached contents', (done) ->
    request(express)
      .get('/?index=1')
      .set('If-Modified-Since', sample(1).stat.mtime.toUTCString())
      .expect(304)
      .expect('')
      .end done

  # 206 Range

  it 'should be get head of partial text', (done) ->
    request(express)
      .get('/?index=1')
      .set('Range', 'bytes=0-1')
      .expect('Content-Length', '2')
      .expect(206)
      .expect('Lo')
      .end done

  it 'should be get first word', (done) ->
    request(express)
      .get('/?index=1')
      .set('Range', 'bytes=0-4')
      .expect('Content-Length', '5')
      .expect(206)
      .expect('Lorem')
      .end done

  it 'should be get next word', (done) ->
    request(express)
      .get('/?index=1')
      .set('Range', 'bytes=6-10')
      .expect('Content-Length', '5')
      .expect(206)
      .expect('ipsum')
      .end done

  it 'should be get all text with partial requesst', (done) ->
    request(express)
      .get('/?index=1')
      .set('Range', "bytes=0-#{sample(1).stat.size - 1}")
      .expect('Content-Length', String(sample(1).stat.size))
      .expect(206)
      .expect(sample(1).text)
      .end done

  it 'should be get cached partial text', (done) ->
    request(express)
      .get('/?index=1')
      .set('If-Modified-Since', sample(1).stat.mtime.toUTCString())
      .set('Range', 'bytes=0-1')
      .expect(304)
      .expect('')
      .end done

  # 206 If-Range

  it 'should be coped with invalid range request', (done) ->
    request(express)
      .get('/?index=1')
      .set('Range', 'bytes=2000-')
      .expect('Content-Length', String(sample(1).stat.size))
      .expect(416)
      .expect(sample(1).text)
      .end done

