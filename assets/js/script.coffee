$ ->
  $(document.body).on "touchmove",(e)->
    e.preventDefault()
  agent = navigator.userAgent
  if(agent.search(/iPhone/) != -1 || agent.search(/iPad/) != -1 || agent.search(/iPod/) != -1)
    $(".container").hide()
    $(".iPhoneLoader").show()
    $(".iPhoneLoader").one "mousedown", ->
      $(".iPhoneLoader").text("Loading...")
      $(".container").show()
      socket = io.connect ''
      window.main = new Main(socket)
      $(".iPhoneLoader").hide()
  else
    $(".iPhoneLoader").hide()
    $(".container").show()
    socket = io.connect ''
    window.main = new Main(socket)

class Main
  constructor: (socket)->
    @synth = new Synth()
    @socket = socket
    @socket.on 'speeds', (data)=>
      for i in [0..15]
        @items[i].speed = data.data[i]
      if data.play?
        for sound in data.play
          if sound is 13
            @synth.play 67,100
            setTimeout =>
              @synth.stop 67
            , 70
          else if sound is 14
            @synth.play 69,100
            setTimeout =>
              @synth.stop 69
            , 70
          else if sound is 15
            @square.play 14
            setTimeout =>
              @square.play 19
            , 100
          else
            @square.play sound
    @square = new Square()
    INPUT_TABLE= {
      90:0
      83:1
      88:2
      68:3
      67:4
      86:5
      71:6
      66:7
      72:8
      78:9
      74:10
      77:11
      188:12
      76:13
      190:14
    }
    $(window).keydown (e)=>
      @socket.emit 'click', { i: INPUT_TABLE[e.keyCode] }
    @items = []
    do @init_stage

  init_stage: ->
    @stage = new createjs.Stage $("#canvas")[0]
    @filter = new createjs.BlurFilter(9, 9, 10)
    @initBG()
    createjs.Ticker.setFPS(60)
    createjs.Ticker.addEventListener "tick", => do @tick
    for i in [0..15]
      @items[i] = new Box(@, i)

  initBG: ->
    @bgparts = []
    cellw = 20*Math.sqrt(3)
    for i in [0..15]
      for j in [0..15]
        @init_bgpart i*60,j*cellw
        @init_bgpart i*60+30,j*cellw+cellw/2
    createjs.Ticker.addEventListener "tick", => 
      target = @bgparts[~~(Math.random()*@bgparts.length)]
      @stage.addChild target
      @stage.setChildIndex target,0
      target.alpha = .5

  init_bgpart: (x,y)->
    shape = new createjs.Shape()
    shape.graphics.f("rgb(255,255,255)") if( Math.random() > 0.9)
    shape.graphics.s("rgb(255,255,255)").drawPolyStar(60, 60, 20, 6, 0, 0)
    shape.alpha = 0.1
    shape.x = x
    shape.y = y
    
    shape.addEventListener "tick", =>
      shape.alpha = Math.max(0, shape.alpha - 0.005)
      @stage.removeChild shape if shape.alpha is 0
    @stage.addChild shape
    @bgparts.push shape

  tick: ->
    @stage.update()

class Box
  constructor: (main, i)->
    @main = main
    @i = i
    @x = i % 4
    @y = ~~(i / 4)
    @speed = 0


    @shape = new createjs.Shape()
    @shape.x = 80 + @x*160
    @shape.y = 80 + @y*160
    @shape.regX = 80
    @shape.regY = 80
    @shape.graphics.beginFill("hsl("+360/16*i+", 100%, 50%)").drawRect(0,0,160,160)
    createjs.Ticker.addEventListener "tick", =>
      @speed = Math.max(0, @speed * 0.95 - 0.2)
      @shape.rotation += @speed
      @shape.scaleX = 0.7 + @speed / 80
      @shape.scaleY = 0.7 + @speed / 80
    @shape.addEventListener "mousedown", =>
      @main.socket.emit 'click', { i: @i }

    @shape.filters = [@main.filter]
    margins = @main.filter.getBounds();
    @shape.cache(margins.x, margins.y, 160+margins.width, 160+margins.height)
     
    @main.stage.addChild @shape




class Square
  BASE = 440
  F = [
    BASE * ( 1 / 1 ),
    BASE * (16 /15 ),
    BASE * ( 9 / 8 ),
    BASE * ( 6 / 5 ),
    BASE * ( 5 / 4 ),
    BASE * ( 4 / 3 ),
    BASE * (45 /32 ),
    BASE * ( 3 / 2 ),
    BASE * ( 8 / 5 ),
    BASE * ( 5 / 3 ),
    BASE * ( 9 / 5 ),
    BASE * (15 / 8 ),
    BASE * ( 1 / 1 ) * 2,
    BASE * (16 /15 ) * 2,
    BASE * ( 9 / 8 ) * 2,
    BASE * ( 6 / 5 ) * 2,
    BASE * ( 5 / 4 ) * 2,
    BASE * ( 4 / 3 ) * 2,
    BASE * (45 /32 ) * 2,
    BASE * ( 3 / 2 ) * 2,
    BASE * ( 8 / 5 ) * 2,
    BASE * ( 5 / 3 ) * 2,
    BASE * ( 9 / 5 ) * 2,
    BASE * (15 / 8 ) * 2,
  ]
  constructor: ->
    if typeof(webkitAudioContext) isnt "undefined"
      @ctx = new webkitAudioContext()
    else if typeof(AudioContext) isnt "undefined"
      @ctx = new AudioContext()
    @osc = []
    @gain = []
 
    for i in [0..24]
      @osc[i] = @ctx.createOscillator()
      @gain[i] = @ctx.createGain()
      @osc[i].connect @gain[i]
      @gain[i].connect @ctx.destination
      @osc[i].start(0)
   
      @osc[i].type = "square"
      @osc[i].frequency.value = F[i]
      @gain[i].gain.value = 0

  play: (i)->
    # @_play i
    # @_play i+4
  # _play: (i)->
    @gain[i].gain.cancelScheduledValues 0
    @gain[i].gain.value = 0.3
    @gain[i].gain.setTargetAtTime 0, 0, 0.3

