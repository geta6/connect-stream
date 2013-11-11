
/*
 * GET home page.
 */

var path = require('path');

exports.index = function(req, res){
  var index = (req.query.index || 1);
  res.stream(path.resolve('tests', 'server', 'public', './sample' + index + '.txt'));
};
