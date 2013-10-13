# connect-stream

  ![](https://nodei.co/npm/connect-stream.png)

  connect-stream adds 206 responsibility to connect (also express).

## install

```
npm install connect-stream
```

## usage

```js
app.use(require('connect-stream')({
  path: path.resolve('public')
}));
app.use(app.router());
app.get('/movie', function (req, res) {
  res.stream('movies/sample.mp4');
});
```

## global options __optional__

* set default value for each `res.stream`.

### path [String]

  * absolute path for streams, default from `path.resolve()`.

### headers [Object]

  * overwrite response headers.

### complete [Function(err, range, src)]

  * function called on end of response.

## method

### res.stream( _filepath_ , _{options}_);

#### filepath [String] __required__

  * relative path from `options.path`
  * if starts with `/` then regard as absolute path.

#### options [Object or Function] __optional__

##### options.headers [Object]

  * overwrite response headers.

##### options.complete [Function(err, range, src)]

  * function called on end of response.
  * `range` is array.
  * `range[0]` is first-byte of HTTP-Range
  * `range[1]` is end-byte of HTTP-Range
  * `src` is absolute path for target.

## Tips

  * `complete` function called multiple on partial request.
  * first of partial request is always `0-1`.
  * for example, when you would like to count up DB, try below.

```
res.stream('movies/test.mp4', function (err, range, src) {
  if (range[0] === 0 && range[1] === 1) {
    Item.find({path: src}, function (err, item) {
      item.playcount++;
      item.save();
    });
  }
});
```


## MIT LICENSE
Copyright &copy; 2013 geta6 licensed under [MIT](http://opensource.org/licenses/MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
