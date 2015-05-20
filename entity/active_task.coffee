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

  #根据项目id，查询活动的服务器列表
  findActiveTask: (project_id, cb)->
    if typeof project_id is 'function'
      cb = project_id
      project_id = null

    sql = "SELECT
        A.hash, A.server, A.timestamp, A.project_id, B.message, B.status, B.url, A.id, A.is_lock
    FROM
        active_task AS A
            left join
        task B ON A.hash = B.hash
            AND A.project_id = B.project_id
            AND A.type = B.type  
            AND A.server = B.target WHERE 1 = 1"

    sql += " AND A.project_id = #{project_id}" if project_id
    @execute sql, cb

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

      self.save data, cb

module.exports = new ActiveTask