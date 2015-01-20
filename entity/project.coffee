#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/19/15 11:50 AM
#    Description:

_BaseEntity = require('bijou').BaseEntity
_async = require 'async'
_ = require 'lodash'

class Project extends _BaseEntity
  constructor: ()->
    super require('../schema/project').schema

  fetch: (cond, cb)->
    cond = cond || {}
    if cond.type is 'task'

    else
      sql = "SELECT * FROM project WHERE token IS NOT NULL"

    @execute sql, cb


module.exports = new Project