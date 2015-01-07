#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:06 PM
#    Description: 执行队列任务

_entity = require '../entity'
_Labor = require('./labor').Labor
_labors = []

(->
  #目前暂时用一个labor
  _labors.push new _Labor()
)()

#执行队列任务
exports.execute = ->
  labor.execute() for labor in _labors