#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:53 PM
#    Description:

_async = require 'async'

_entity = require '../entity'
_enum = require('../enumerate').TaskStatus
_build = require './build'
_transport = require './transport'
_delivery = require './delivery'
_bhfProxy = require './bhf-proxy'
_utils = require '../utils'
_release = require './release'
_config = require '../config'

class Labor
  isRunning: false
  runningTask: null
  #constructor: ()->

  #执行任务
  executeTask: (task, cb)->
    self = @
    queue = []

    #执行build操作
    queue.push(
      (done)-> _build.execute task, done
    )

    #执行分发，如果是preview的话，则
    queue.push(
      (done)->
#        return done null if task.type isnt 'preview'
        _delivery.execute task, (err)-> done err
    )

#    #提交到svn，如果是release的话
#    queue.push(
#      (done)->
#        return done null if task.type isnt 'release'
#        _release.execute task, done
#    )

    #更新活动服务器
    queue.push(
      (done)->
        _entity.active_task.updateActiveTask task.project_id, task.target, task.type, task.hash, done
    )

    _async.waterfall queue, (err)->
      task.status = if err then _enum.Failure else _enum.Success
      self.finishTask task, (otherErr)-> cb(err || otherErr)

  #完成任务的操作
  finishTask: (task, cb)->
    self = @
    task.failure_counter++ if task.status isnt _enum.Success
    task.last_execute = new Date().valueOf()
    _entity.task.save task, (err)->
      _utils.emitEvent 'task:stop', task
      self.runningTask =  null
      cb err

  #获取任务，如果没有指定任务id，则获取最前一条
  getTask: (task_id, cb)->
    if task_id
      _entity.task.getTaskById task_id, cb
    else
      _entity.task.getForemostTask cb

  execute: (task_id, uuid)->
    return if @isRunning

    self = @
    @isRunning = true
    task = null
    queue = []

    #获取task
    queue.push(
      (done)->
        self.getTask task_id, (err, result)->
          task = result
          done err
    )

    #如果有指定uuid，则获取该uuid对应的任务
    queue.push(
      (done)->
        #
        if task?.type is 'release'
          task.delivery_server = _config.release.server
          return done null

        return done null if not (uuid and task)
        cond = uuid: uuid
        _entity.delivery_server.findOne cond, (err, result)->
          return done err if err or not result
          task.delivery_server = result.server
          task.target = uuid
          done err
    )

    _async.waterfall queue, (err)->
      if err
        console.log err
        message = "执行任务发生错误：#{err.message}"
        _utils.emitRealLog message
        self.isRunning = false
        return

      #没有任务了
      if not task
        message = if task_id then "没有找到可执行的任务" else "所有任务都已经完成"
        _utils.emitRealLog message
        self.isRunning = false
        return

      self.runningTask =  task
      _utils.emitEvent 'task:start', task

      #该任务没有找到递送服务器，preview的类型，必需指定递送服务器
      if task.type is 'preview' and not task.delivery_server
        _utils.emitRealLog(
          description: '任务没有合法的递送服务器'
          task: task
          type: 'task'
        )

        task.status = _enum.ServerNotFound
        return self.finishTask task, (err)->
          self.isRunning = false
          self.execute()

      _utils.emitRealLog (
        description: "提取任务执行"
        task: task
        type: 'task'
        process: 'start'
      )

      #执行任务
      self.executeTask task, (err)->
        self.isRunning = false
        if err
          description = "任务执行失败"
          console.log JSON.stringify(err).red
        else
          description = "任务执行完成，成功分发至#{task.delivery_server}"

        _utils.emitRealLog(
          description: description
          task: task
          type: 'task'
          success: !err
          process: 'end'
          error: err
        )

        #继续执行任务
        self.execute()

exports.Labor = Labor