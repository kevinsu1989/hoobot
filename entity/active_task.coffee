#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 3/16/15 2:42 PM
#    Description:

_BaseEntity = require('bijou').BaseEntity
_async = require 'async'
_ = require 'lodash'

class ActiveTask extends _BaseEntity
  constructor: ()->
    super require('../schema/active_task').schema

  #检查
  updateActiveTask: (project_id, server, type, hash, cb)->
    self = @
    cond =
      project_id: project_id
      server: server
      type: type

    @findOne cond, (err, result)->
      return cb err if err

      data = _.extend server: server, cond
      data.hash = hash
      data.timestamp = new Date().valueOf()
      data.id = result.id if result

      console.log data
      self.save data, cb

module.exports = new ActiveTask