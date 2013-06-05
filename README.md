# connect-stream

  connect-stream extends `206 Partial Content` responsibility of express.

  you can stream static binary file anyway.
  
  cache `file descripter` and `fs.stat`.


## update

  * `v0.2` initial method change.
  * `v0.1` stream method change.
  * `v0.0` develop

## roadmap

  * `v0.4` use as static module
  * `v0.3` content cache
  * ✓ `v0.2` fd cache
  * ✓ `v0.1` ReadbleStream

## install

```
npm install connect-stream
```

## usage

### configure

```
app.use(require('connect-stream')({/* global options */}));
app.use(app.router());
```

### global options

  default options here.

```
{
    path: path.resolve('public'),
    fd: {
      max: 1000
      maxAge: 1000 * 60 * 60
    },
    stat: {
      max: 5000,
      maxAge: 1000 * 60
    }
}
```


### response

```
app.get('/movie', function (req, res) {
  res.stream('sample.mp4');
});
```

## arguments

### res.stream( _filepath_ , _[options]_);

#### filepath &lt;String&gt;

  * __required__
  * realtive path from `global_options.path`
  * if starts with `/` then regard `filepath` as absolute path.

#### options &lt;Object&gt;

  * __optional__

##### headers &lt;Object&gt;

  * add/overwrite response header

##### success &lt;function(err, stat, [ini, end])&gt;

  * called on success to response
  * __already sent headers__

###### Arguments

  * `err` always `null`
  * `stat` is `fs.stat` result
  * `ini` is first-byte of HTTP-Range
  * `end` is end-byte of HTTP-Range

##### failure &lt;function(err, stat [ini, end])&gt;

  * called on failure to response
  * __need to send response manually__
  * if omit this function, send text `Cannot #{METHOD} #{ROUTE}` with 404 status

###### Arguments

  * `err` is `Error` object
  * `stat` is `fs.stat` result
  * `ini` is first-byte of HTTP-Range
  * `end` is end-byte of HTTP-Range

## tips

  * `success` function called multiple on partial request
  * for example, when you would like to count up DB, try this

```
res.stream('test.mp4', {
  success: function (err, stat, range) {
    if (range[0] === 0 && range[1] === 1) {
      Item.countUp()
    }
  }
});
```

  * first partial request is always `range = [0, 1]`.
  * `connect-stream` pass `range = [0, 1]` on `304`

## 日本語でおk

* HWやネットワークに制約のある環境・及びモダンなブラウザでは、巨大なサイズが想定されるMIME-TYPEコンテンツに対して、`Range`というリクエストヘッダを送出します。
* `Range`の中には「何バイト目から何バイト目まで寄越せ」という指示が入っているので、指示に従いsplitして返送します。
* これを正しく処理できないと、iPhoneやAndroidなどでは「再生できるはずの動画フォーマットなのに不正なフォーマットと言われる」というエラーが発生します。
* `connect-stream`では、`Range`が存在する場合には上記処理を、存在しない場合には通常通り返送します。
* 文字通り、`ReadableStream`での返送を行います。
* `If-Modified-Since`や`If-Not-Match`との比較も行い、適切な`304`レスポンスを送出します。
* `file descripter`と`fs.stat`の結果についてはキャッシュを取ります、コンテンツキャッシュはクライアントに任せる形態を取っています。

---

&copy; 2013 geta6
