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
_enum = require '../enumerate'

exports.postOnly = (client, cb)->
  cb null, "此API仅支持POST请求"

#直接处理task，目前主要用于honey-preview提交数据
#要求数据是已经处理过，直接可以保存到数据库的信息，能提交到这里的，表示确定已经是分发成功的
exports.saveTask = (data, cb)->
  queue = []
  #获取对应的项目id
  queue.push(
    (done)->
      cond = repos_git: data.repos_git
      _entity.project.findOne cond, (err, result)->
        return done err if err
        data.project_id = result?.id
        done err
  )

  #根据git地址，获取对应的项目，如果没有项目存在，则插入新的项目
  queue.push(
    (done)->
      return done null if data.project_id

      projectData =
        repos_git: data.repos_git
        repos_url: data.repos_url
        timestamp: new Date().valueOf()
        repos_name: _utils.extractProjectName data.repos_url

      _entity.project.save projectData, (err, id)->
        data.project_id = id
        done err
  )

  #保存任务
  queue.push(
    (done)->
      data.status = _enum.TaskStatus.Success
      _githook.insertOrUpdateTask data, done
  )

  #保存到active_task
  queue.push(
    (done)->
      _entity.active_task.updateActiveTask data.project_id, data.target, data.type, data.hash, done
  )

  _async.waterfall queue, (err)-> cb err

#接收并处理githook，仅支持push events
exports.gitHook = (data, cb)->
  if not (data.repository and data.commits?.length)
    result =
      success: true
      #忽略非push event
      ignore: true

    _utils.emitRealLog '收到非法的web hook'
    return cb null, result

  _githook.execute data, (err, taskCount)->
    log = if err then err else "共有 #{taskCount}条任务进入队列"
    _utils.emitRealLog log
    result = success: true if not err
    cb err, result

    #如果插入成功，则执行任务
    _supervisor.execute() if not err

#获取任务列表
exports.getTask = (query, cb)->
  cond = project_id: query.project_id
  cond.type = query.type if query.type

  options =
    orderBy:
      timestamp: 'DESC'

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


#保存项目信息
exports.saveProject = (data, cb)->
  _entity.project.save data, cb

#删除项目信息
exports.removeProject = (id, cb)->
  _entity.project.removeById id, cb

#获取项目
exports.getProject = (cond, cb)->
  cond = cond || {}
  return _entity.task.getAllProject cb if cond.type is 'preview'

  _entity.project.fetch cond, (err, result)->
    _.map result, (item)->
      cache = _tags.getTags(item.id)
      item.online = cache?.success
      item.error = cache?.error

    cb err, result

#发布
exports.release = (data, cb)->
  queue = []
  task_id = 0

  #return console.log data

  #第一步，检测是否在任务当中
  queue.push(
    (done)->
      cond =
        type: 'release'
        hash: data.commit.id

      _entity.task.findOne cond, (err, result)->
        return done err if err
        task_id = result.id if result

        #不需要更改状态
        return done err if result?.status is _enum.TaskStatus.Created

        updateData = status: _enum.TaskStatus.Created
        _entity.task.updateById task_id, updateData, (err)-> done err
  )

  #可能需要创建任务
  queue.push(
    (done)->
      return done null if task_id
      taskData =
        project_id: data.project_id
        hash: data.commit.id
        message: data.commit.message
        email: data.commit.committer_email
        timestamp: new Date(data.commit.committed_date).valueOf()
        status: _enum.TaskStatus.Created
        repos: data.ssh_git
        type: 'release'

      _entity.task.save taskData, (err, id)->
        task_id = id
        done err
  )

  #执行任务
  queue.push(
    (done)->
      if _supervisor.runningTask
        err = _http.notAcceptableError("其它任务正在运行中，请稍候再试")
        return done err

      done null
  )

  _async.waterfall queue, (err)->
    cb err, task_id
    _supervisor.runTask task_id if not err