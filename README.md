# Connect Stream

  ![](https://travis-ci.org/geta6/connect-stream.png)

  Serving static file with the given path.
  Inspired by [isaacs/st](https://github.com/isaacs/st).

  * compatible with return code `200`, `206`, `304`, `403`, `404`, `500`
  * cache fd, stat and gzip content
  * gzip deflatable
  * useful to serve movie to mobile device

## Install

```
$ npm install connect-stream
```

## Usage

  Include in your project:

```javascript
var connect_stream = require('connect-stream');
app.use(connect_stream(__dirname + 'public'));
```

  Use in your routes:

```javascript
app.get(function (req, res) {
  return res.stream('movie.mp4');
});
```

  * It returns `200` if normal request.
  * It returns `206` if partial request.
  * It returns `304` if ETag or Modified-Since matched.
  * It returns `404` if `movie.mp4` not exists.
  * It returns `403` if `movie.mp4` permission denied.
  * It returns `500` if error.

## How to use

  `connect-stream` respond to Range Request (HTTP 206) correctly.

  [14.35 Range - W3, RFC2616](http://www.w3.org/Protocols/rfc2616/rfc2616.txt)

  Here are all the options described with their defaults values and a few possible settings you might choose to use:

```javascript
stream = require('connect-stream');

app.use(stream(path.resolve('public'), { // root path for static files. defaults to `process.cwd()`
  trim: false, // do not trim query strings
  trim: true, // trim all query strings using url.parse

  concatenate: 'resolve', // use path.resolve on concatenate root and src path
  concatenate: 'join', // use path.join on concatenate root and src path

  passthrough: true, // calls next() instead of returning a 404 error
  passthrough: false, // returns 404 when a file is not found

  cache: { // specify cache:false to turn off caching entirely
    fd: {
      max: 1000, // number of fd's to hang on to
      maxAge: 1000 * 60 * 60, // amount of ms before fd's expire
    },

    stat: {
      max: 5000, // number of stat objects to hang on to
      maxAge: 1000 * 60, // number of ms that stats are good for
    },

    content: {
      max: 1024 * 1024 * 64, // how much memory to use on caching contents
      maxAge: 1000 * 60 * 10, // how long to cache contents for
    }
  }
}));

var callback = function (err, range, isFirstStream) {
  console.error(err); // instanceof Error or null
  console.log(range);
  // isArray ([ini, end])         : on range request
  // isArray ([0, stat.size - 1]) : on normal request
  // Null                         : on error
  console.log(isFirstStream);
  // bool, request is first range request or not
};

app.get(/^\/(.*)\.mp4$/, function (req, res) {
  res.stream(req.params[0] + '.mp4', callback);
});

var options = {
  headers: {
    'content-type': 'application/octet-stream',
    'cache-control': 'public'
  }
};

app.get(/^\/download\/(.*)\.mp4$/, function (req, res) {
  res.stream(req.params[0] + '.mp4', options, callback);
});
```


## Upgrade Guide (0.x -> 1.x)

### interface

```javascript
app.use(require('connect-stream'));    // old
app.use(require('connect-stream')());  // new
```


### behavior

```javascript
var stream = require('connect-stream');
app.use(stream(path.resolve('public')));

app.get(function (req, res) {
  res.stream('/tmp/a.mp4');
  // old, always stream "/tmp/a.mp4"
  // new, stream from "public/tmp/a.mp4"
});
```

```javascript
var stream = require('connect-stream');
app.use(stream(path.resolve('public'), {
  concatenate: 'resolve'
});

app.get(function (req, res) {
  res.stream('/tmp/a.mp4');
  // old, always stream "/tmp/a.mp4"
  // new, stream from "/tmp/a.mp4"
});
```


## Tips

### count up your database on range request (e.g. playing movie)

  range-request requests sequential at one request.

  you should use filter in callback for count up play-times.

  Example:

```javascript
app.get('/movie.mp4', function (req, res) {
  res.stream('movie.mp4', function (err, range, isFirstStream) {
    if (isFirstStream) {
      countUpYourDatabaseHere();
    }
  });
});
```

## MIT LICENSE

Copyright &copy; 2013 geta6 licensed under [MIT](http://opensource.org/licenses/MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
