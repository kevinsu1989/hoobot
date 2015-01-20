#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 10:07 AM
#    Description: 处理githook
_async = require 'async'
_http = require('bijou').http
_ = require 'lodash'

_entity = require '../entity'
_githook = require './githook'
_supervisor = require './supervisor'
_utils = require '../utils'
_deploy = require './deploy'
_tags = require './tags'

exports.postOnly = (client, cb)->
  console.log 'abc'
  cb null, "此API仅支持POST请求"

#接收并处理githook，仅支持push events
exports.gitHook = (data, cb)->
  if not (data.repository and data.commits?.length)
    result =
      success: true
      #忽略非push event
      ignore: true

    _utils.emitRealLog '收到非法的web hook'
    return cb null, result

  _githook.execute client.body, (err, taskCount)->
    log = if err then err else "共有 #{taskCount}条任务进入队列"
    _utils.emitRealLog log
    result = success: true if not err
    cb err, result

    #如果插入成功，则执行任务
    _supervisor.execute() if not err

#获取任务列表
exports.getTask = (query, cb)->
  cond = project_id: query.project_id
  options =
    pagination: _entity.task.pagination query.pageIndex, query.pageSize
  _entity.task.find cond, options, cb

#获取服务器列表
exports.getDeliveryServer = (query, cb)->
  entity = _entity.delivery_server
  pagination = entity.pagination query.pageIndex
  options = pagination: pagination
  entity.find {}, options, cb

#保存分发服务器
exports.saveDeliveryServer = (data, cb)->
  notMatches = {}
  notMatches.id = data.id if data.id

  cond = uuid: data.uuid

  queue = []
  queue.push(
    (done)->
    _entity.delivery_server.exists {}, cond, notMatches, (err, total)->
      return done err if err
      err = _http.notAcceptableError("UUID #{data.uuid}已经存在") if total > 0
      done err
  )

  queue.push(
    (done)->
      _entity.save data, done
  )

  _async.waterfall queue, cb

#删除分发服务器
exports.deleteDeliveryServer = (id, cb)->
  _entity.removeById id, cb

#获取所有的项目列表
exports.getPreviewProject = (cb)->
  _entity.task.getAllProject cb

#保存项目信息
exports.saveProject = (data, cb)->
  _entity.project.save data, cb

#删除项目信息
exports.removeProject = (id, cb)->
  _entity.project.removeById id, cb

exports.getProject = (cond, cb)->
  cond = cond || {}
  if cond.type is 'preview'
    return exports.getPreviewProject(cb)

  _entity.project.fetch cond, (err, result)->
    _.map result, (item)->
      cache = _tags.getTags(item.id)
      item.online = cache?.success
      item.error = cache?.error

    cb err, result
