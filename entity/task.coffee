#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:22 PM
#    Description:

_BaseEntity = require('bijou').BaseEntity
_async = require 'async'
_ = require 'lodash'
_enum = require '../enumerate'

class Task extends _BaseEntity
  constructor: ()->
    super require('../schema/task').schema

  #获取最前的Task，每个项目只取最新一条，一个项目多次build没有意义
  getForemostTask: (cb)->
    sql = "
            SELECT
          C . *, D.server AS delivery_server
      FROM
          (SELECT
              project_id,
                  (SELECT
                          id
                      FROM
                          task X
                      WHERE
                          X.status = 1
                              AND X.project_id = A.project_id
                      ORDER BY X.id DESC
                      LIMIT 1) AS task_id
          FROM
              task A
          WHERE
              A.status = 1
          GROUP BY project_id) B
              LEFT JOIN
          task C ON B.task_id = C.id
              LEFT JOIN
          delivery_server D ON C.target = D.uuid
      ORDER BY C.id ASC
      LIMIT 1"

    @execute sql, (err, result)->
      return cb err if err
      task = if result.length >= 0 then result[0] else undefined
      cb err, task

  #获取所有的项目，并按最近提交的排序
  getAllProject: (cb)->
    sql = "SELECT
          C . *
      FROM
          (SELECT
              project_id,
                  (SELECT
                          id
                      FROM
                          task X
                      WHERE
                          X.project_id = A.project_id
                      ORDER BY X.status DESC , X.timestamp DESC
                      LIMIT 1) AS task_id
          FROM
              task A
          GROUP BY project_id) B
              LEFT JOIN
          task C ON B.task_id = C.id
      ORDER BY C.timestamp DESC"

    @execute sql, cb

module.exports = new Task