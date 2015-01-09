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

#特殊路由
specialRouter = (app)->
  app.get '/', (req, res, next)-> res.sendfile 'static/index.html'

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
    root: '/api/'

    #指定数据库链接
    database: _config.database
    #指定业务逻辑的文件夹
    biz: './biz'
    #指定路由的配置文件
    routers: require './routers'
    #处理之前
    #onBeforeHandler: (client, req, cb)->
    #请求访问许可
    #requestPermission: (client, router, action, cb)->

  _bijou.initalize(app, options)

  queue = []
  queue.push(
    (done)->
      #扫描schema，并初始化数据库
      schema = _path.join __dirname, './schema'
      _bijou.scanSchema schema, done
  )

  #如果没有用户，则创建一个root用户
#  queue.push(
#    (done)-> initRootMember done
#  )

  _async.waterfall queue, (err)->
    console.log err if err
    console.log 'BHF is running now!'

module.exports = (app)->
  #确定所依赖的命令都存在
  ensureCommandDepends()
  #处理特殊路由
  specialRouter app
  #初始化bijou
  initBijou app
  #执行任务
  _supervisor.execute()