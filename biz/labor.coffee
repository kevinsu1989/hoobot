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

class Labor
  isRunning: false
  #constructor: ()->

  #执行任务
  executeTask: (task, cb)->
    self = @
    queue = []

    #执行build操作
    queue.push(
      (done)-> _build.execute task, done
    )

    #执行分发
    queue.push(
      (done)-> _delivery.execute task, done
    )

    _async.waterfall queue, (err)->
      status = if err then _enum.Failure else _enum.Success
      self.finishTask task, status, cb

  #完成任务的操作
  finishTask: (task, status, cb)->
    task.failure_counter++ if not status isnt _enum.Success
    _entity.task.save task, (err)-> cb err

  execute: ()->
    return if @isRunning

    self = @
    @isRunning = true
    #获取最前的一条任务
    _entity.task.getForemostTask (err, task)->
      #没有任务了
      if not task
        _utils.emitRealLog '所有任务都已经完成'
        self.isRunning = false
        return

      #该任务没有找到递送服务器
      if not task.delivery_server
        _utils.emitRealLog(
          message: '任务没有合法的递送服务器'
          task: task
          type: 'task'
        )

        return self.finishTask task, _enum.ServerNotFound, (err)->
          self.isRunning = false
          self.execute()

      _utils.emitRealLog (
        message: '提取任务#{task.id}执行'
        task: task
        type: 'task'
        process: 'start'
      )

      #执行任务
      self.executeTask task, (err)->
        self.isRunning = false
        _utils.emitRealLog(
          message: '任务执行完成'
          task: task
          type: 'task'
          process: 'end'
          error: err
        )

        #继续执行任务
        self.execute()

exports.Labor = Labor