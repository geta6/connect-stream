var express = require('express');
var routes = require('./routes');
var path = require('path');

var app = express();
var stream = require('../../');

app.set('port', process.env.PORT || 3000);
app.use(express.favicon());
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(stream(path.resolve('tests', 'server', 'public')));
app.use(app.router);
app.use(express.errorHandler());

app.get('/', function(req, res) {
  res.setHeader('content-type', 'text/html');
  res.end('<video src="/sample.mp4" width="100%" controls autoplay></video><img src="/sample.png" width="100%">')
});

app.get(/\/(.*)/, function (req, res) {
  res.stream(req.params[0], function (err, range, isFirstStream) {
    //console.log(isFirstStream);
    //console.log('range', range);
    //console.log('partial', partial);
  });
});

module.exports = app
