#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 6:01 PM
#    Description:

_path = require("path")
_bijou = require("bijou")
_ = require 'lodash'
_async = require 'async'
_fs = require 'fs-extra'

_config = require './config'
_entity = require './entity'
_utils = require './utils'
_supervisor = require './biz/supervisor'
_status = require './biz/status'
_api = require './biz/api'

#确保所依赖的命令是否存在
ensureCommandDepends = ()->
  depends = ['git', 'zip']

  #检测依赖
  while depends.length > 0
    depend = depends.pop()
    exists = which depend

    #所依赖的命令不存在则直接退出
    if not exists
      console.log "#{depend} not found".red
      process.exit 1

#初始化bijou
initBijou = (app)->
  options =
    log: process.env.DEBUG
    #指定数据库链接
    database: _config.database
    #指定路由的配置文件
    routers: []
  _bijou.initalize(app, options)

  queue = []
  queue.push(
    (done)->
      #扫描schema，并初始化数据库
      schema = _path.join __dirname, './schema'
      _bijou.scanSchema schema, done
  )


  _async.waterfall queue, (err)->
    console.log err if err
    console.log 'BHF is running now!'

module.exports = (app)->
  #确定所依赖的命令都存在
  ensureCommandDepends()
  #初始化bijou
  initBijou app
  #初始化路由
  require('./router').init(app)
  _supervisor.execute()
  _status.init()