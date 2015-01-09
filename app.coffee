#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 4:55 PM
#    Description:

_express = require 'express.io'
_http = require 'http'
_app = _express()
_path = require 'path'
_redisStore = new require('connect-redis')(_express)
_coffeeMiddleware = require('coffee-middleware')
_app.http().io()
require 'shelljs/global'
require 'colors'

_utils = require './utils'
_config = require './config'

_app.configure(()->
  _app.use(_express.methodOverride())
  _app.use(_express.bodyParser(
    uploadDir: _config.uploadTemporary
    limit: '1024mb'
    keepExtensions: true
  ))

  _app.use(_coffeeMiddleware({
    src: __dirname + '/static'
    compress: false
  }))

  _app.use(_express.cookieParser())
  _app.use(_express.session(
    secret: 'hunantv.com'
  #cookie:  maxAge: 1 * 60 * 60 * 1000
    store: new _redisStore(
      ttl: 60 * 60 * 24 * 365
      prefix: "#{_config.redis.unique}:session:"
      host: _config.redis.server
      port: _config.redis.port
    )
  ))
  _app.use(_express.static(__dirname + '/static'))
  _app.set 'port', _config.port.delivery || 1518
)

#链接后的处理
_app.io.route 'ready', (socket)->
  text = "hi, 我就是机器人Hoobot了，现在的服务器工作是灰常正常滴"
  _utils.emitRealLog text, 'green'

_utils.onRealLog (data)-> _app.io.broadcast('realtime', data)

require('./initialize')(_app)

_app.listen _app.get 'port'

console.log "Port: #{_app.get 'port'}, Now: #{new Date()}"