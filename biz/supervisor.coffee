#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:06 PM
#    Description: 执行队列任务

_entity = require '../entity'
_Labor = require('./labor').Labor
_labor = new _Labor()

#执行队列任务
exports.execute = ->
  _labor.execute()

#强行执行某个任务，必需没有任务执行
exports.runTask = (task_id, uuid)->
  return false if _labor.isRunning
  _labor.execute task_id, uuid
  return true

exports.runningTask = _labor.runningTask