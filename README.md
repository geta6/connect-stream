# connect-stream

connect (express) middleware for _206 Partial Content_.

## update

`v0.0.3` -> `v0.1.0`, check out arguments.

now `Buffer` is not acceptable.

## about

connect-stream extends responsibility of `206 Partial Content` request.

now, you can stream large binary file (something like __H.264 mp4__ or __mp3 audio__ and more) to mobile device.

---

connect-streamは`206 Partial Content`への応答能力を拡張します。

モバイルデバイスに対して __H.264 mp4__ や __mp3 audio__ のようなバイナリファイルをストリーミング配信できます。

## install

```
npm install connect-stream
```

## usage

### configure

```
app.use(require('connect-stream'));
app.use(app.router());
```

should be `use` before `app.router`

#### response

```
app.get '/movie', (req, res) ->
  res.stream (path.resolve 'public', 'sample.mp4'), ->
    res.writeHead 404
    res.end 'Document Not Found'
```

## arguments

### res.stream( _filepath_ , _[headers]_ , _[failure]_ );
### res.stream( _filepath_ , _[failure]_ );
### res.stream( _filepath_ );

#### filepath &lt;String&gt;

* required
* use `path.resolve` if not starts with `/`

#### headers &lt;Object&gt;

* optional, defalut `{}`
* add/overwrite response header

#### failure &lt;Function&gt;

* optional, execute on failure stream
  * on `!fs.existsSync(filepath)`
  * on `stream.on('error')`

---

&copy; 2013 geta6
