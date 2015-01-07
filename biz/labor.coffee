#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:53 PM
#    Description:

_async = require 'async'

_entity = require '../entity'
_enum = require '../enumerate'
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
      self.finishTask task, !err, cb

  #完成任务的操作
  finishTask: (task, success, cb)->
    enumStatus = _enum.TaskStatus
    task.status = if success then enumStatus.Success else enumStatus.Failure
    task.failure_counter++ if not success

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

      #执行任务
      self.executeTask task, (err)->
        console.log 'done'.red
        self.isRunning = false
        #继续执行任务
        self.execute()

exports.Labor = Labor