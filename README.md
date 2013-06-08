# connect-stream

  connect-stream extends `206 Partial Content` responsibility of express.

  you can stream static binary file anyway.

  cache `file descriptor` and `fs.stat`.


## update

  * `v0.3` using st
  * `v0.2` initial method change.
  * `v0.1` stream method change.
  * `v0.0` develop

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

  options as same as [isaacs/st](https://github.com/isaacs/st)

```
{
  static: true,
  url: '/',
  path: path.resolve('public'),
  index: false,
  passthrough: true
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
  * relative path from `global_options.path`
  * if starts with `/` then regard `filepath` as absolute path.

#### options &lt;Object&gt;

  * __optional__

##### debug &lt;Boolean&gt;

  * turn on debug mode (logging path, fd, memoryUsage)

##### headers &lt;Object&gt;

  * add/overwrite response header

##### complete &lt;function(err, ini, end)&gt;

  * called on end of response
  * `ini` is first-byte of HTTP-Range
  * `end` is end-byte of HTTP-Range

##### `Function`

  * attach to `complete` function

## Tips

  * `complete` function called multiple on partial request
  * for example, when you would like to count up DB, try this

```
res.stream('test.mp4', function (err, ini, end) {
  if (ini === 0 && end === 1) {
    countUpItem()
  }
});
```
  * first partial request is always `0-1`.
  * `connect-stream` pass `0-1` on `304`

## 日本語でおk

* HWやネットワークに制約のある環境・及びモダンなブラウザでは、巨大なサイズが想定されるMIME-TYPEコンテンツに対して、`Range`というリクエストヘッダを送出します。
* `Range`の中には「何バイト目から何バイト目まで寄越せ」という指示が入っているので、指示に従いsplitして返送します。
* これを正しく処理できないと、iPhoneやAndroidなどでは「再生できるはずの動画フォーマットなのに不正なフォーマットと言われる」というエラーが発生します。
* `connect-stream`では、`Range`が存在する場合には上記処理を、存在しない場合には通常通り返送します。
* 文字通り、`ReadableStream`での返送を行います。
* `If-Modified-Since`や`If-Not-Match`との比較も行い、適切な`304`レスポンスを送出します。
* `file descriptor`と`fs.stat`の結果についてはキャッシュを取ります、コンテンツキャッシュはクライアントに任せる形態を取っています。

---

&copy; 2013 geta6
