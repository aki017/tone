
###
Module dependencies.
###
express = require("express")
http = require("http")
path = require("path")
app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use require('connect-assets')()
app.use express.static __dirname + '/public'

# development only
app.use express.errorHandler()  if "development" is app.get("env")
app.get "/", (req, res)-> res.render('index')
server = http.createServer(app)
server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

io = require('socket.io').listen server
speeds = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

play = (i)->
  speeds[i] += 10 + Math.random() * 20
  io.sockets.emit 'speeds', { data: speeds, play: [i]}

(->
  counter = 0
  setInterval ->
    counter++
    i = 13
    i = 14 if counter%4 == 3
    play i
  , 1000 * 60 / 130
)()

setInterval ->
  for i in [0..15]
    speeds[i] = Math.max(0, speeds[i] * 0.95 - 0.2)
, 1000 / 60

io.sockets.on 'connection', (socket)->
  socket.emit 'speeds', { data: speeds }
  socket.on 'click', (data)->
    if data.i?
      play +data.i

