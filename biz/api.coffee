#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 10:07 AM
#    Description: 处理githook
_async = require 'async'
_http = require('bijou').http

_entity = require '../entity'
_githook = require './githook'
_supervisor = require './supervisor'
_utils = require '../utils'
_deploy = require './deploy'

#接收并处理githook，仅支持push events
exports.gitHook = (client, cb)->
  data = client.body
  if not (data.repository and data.commits?.length)
    result =
      success: true
      #忽略非push event
      ignore: true

    return cb null, result

  _githook.execute client.body, (err, success)->
    console.log err if err
    result = success: true if success
    cb err, result
    #如果插入成功，则执行任务
    _supervisor.execute() if success

#获取任务列表
exports.getTask = (client, cb)->

#获取服务器列表
exports.getDeliveryServer = (client, cb)->
  id = client.params.id
  return _entity.delivery_server.findById id, cb

  entity = _entity.delivery_server
  pagination = entity.pagination client.query.pageIndex
  options = pagination: pagination
  entity.find {}, options, cb

#保存分发服务器
exports.saveDeliveryServer = (client, cb)->
  data = client.body
  data.id = client.params.id

  notMatches = {}
  notMatches.id = data.id if data.id

  cond = uuid: data.uuid

  queue = []
  queue.push(
    (done)->
    _entity.delivery_server.exists {}, cond, notMatches, (err, total)->
      return done err if err
      err = _http.notAcceptableError("UUID #{data.uuid}已经存在") if total > 0
      return done err
  )

  queue.push(
    (done)->
      _entity.save data, done
  )

  _async.waterfall queue, cb

#删除分发服务器
exports.deleteDeliveryServer = (client, cb)->
  id = client.params.id
  _entity.removeById id, cb

#获取所有的项目列表
exports.getProject = (client, cb)->

#强行执行某个任务，一般用于因滚操作
exports.runTask = (client, cb)->
