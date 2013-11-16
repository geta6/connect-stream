# connect-stream

  Serving static file with the given paths.

  Inspired by [isaacs/st](https://github.com/isaacs/st)

  ![](https://nodei.co/npm/connect-stream.png)

  ![](https://travis-ci.org/geta6/connect-stream.png)


## install

    npm i connect-stream

## usage

  connect-stream respond to Partial-Content Request correctly.

  Here are all the options described with their defaults values and a few possible settings you might choose to use:

    stream = require('connect-stream');

    app.use(stream(path.resolve('public'), { // root path for static files. defaults to `/`
      trim: false, // do not trim query strings
      trim: true, // trim all query strings using url.parse

      concatenate: 'resolve', // use path.resolve on concatenate root and src path
      concatenate: 'join', // use path.join on concatenate root and src path

      passthrough: true, // calls next/returns instead of returning a 404 error
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

    app.get(/^\/(.*)\.mp4$/, function (req, res) {
      res.stream(req.params[0] + '.mp4');
    });

## upgrade guide

* some method chaged.
  * setup interface
  * internal behavior

### example

```
app.use require 'connect-stream'     # old
app.use (require 'connect-stream')() # new
```

## feature

### gzip

  browser requested with encoding 'gzip' allowed, returns gzip stream with 200.

### cache

#### server side

  file descriptor, `fs.stat` and gzipped content will be cached with configured caching storategies.

  partial response don't allowed gzip encoding, that content won't be cached.

#### client side

  captured `if-modified-since` or `if-none-match`, return 304.

### behavior

#### concatenate

##### join method

    app.use(stream(path.resolve('public')));

    app.get('/a.mp4', function (req, res) {
      res.stream('/a.mp4'); // returns "./public/a.mp4"
    });

##### resolve method

    app.use(stream(path.resolve('public'), {
      concatenate: 'resolve'
    }));

    app.get('/a.mp4', function (req, res) {
      res.stream('/tmp/a.mp4'); // returns "/tmp/a.mp4"
    });

#### passthrough

##### true

    app.use(stream(path.resolve('public')));
    app.use(function (req, res) {
      res.stream(path.resolve('public', '404.html')); // returns 404.html with 404
    });

    app.get('/notexists.mp4', function (req, res) {
      res.stream('/notexists.mp4'); // call next()
    });

##### false

    app.use(stream(path.resolve('public')));
    app.use(function (req, res) {
      res.stream(path.resolve('public', '404.html')); // ignored
    });
    app.use(express.errorHandler()); // called

    app.get('/notexists.mp4', function (req, res) {
      res.stream('/notexists.mp4'); // call next(err)
    });

## MIT LICENSE

Copyright &copy; 2013 geta6 licensed under [MIT](http://opensource.org/licenses/MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
