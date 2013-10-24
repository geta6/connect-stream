
/*
 * GET home page.
 */

exports.index = function(req, res){
  var index = (req.query.index || 1);
  res.stream('/sample' + index + '.txt');
};
