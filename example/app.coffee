http = require 'http'
path = require 'path'
express = require 'express'

app = express()

app.set 'port', process.env.PORT || 3001
app.use express.favicon()
app.use express.logger 'dev'
app.use express.bodyParser()
app.use express.methodOverride()
app.use require '../'
app.use app.router
app.use express.static path.join __dirname, 'public'
app.use express.errorHandler()

app.get '/', (req, res, next) ->
  res.stream (path.resolve 'public', 'sample.mp4'), ->
    res.writeHead 404
    res.end 'Document Not Found'

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get 'port'}"
