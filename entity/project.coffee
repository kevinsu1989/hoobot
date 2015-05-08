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
    sql = "SELECT * FROM project WHERE 1 = 1"
    cond = cond || {}
    sql += " AND repos_git LIKE '%honey-lab%'" if cond.honeyLabOnly
    @execute sql, cb

  getGitUsers: (cb)->
    sql = "SELECT DISTINCT(git_username) FROM project"
    @execute sql, cb

module.exports = new Project