#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:54 PM
#    Description: 分析并处理git hooks
_ = require 'lodash'
_entity = require '../entity'
_transport = require './transport'
_utils = require '../utils'
_async = require 'async'
_enum = require '../enumerate'
_bhfProxy = require './bhf-proxy'

#保存单条任务
insertTask = (task, cb)->
  queue = []

  #将相同项目的status为created都改掉，因为一个项目不需要重复
  queue.push(
    (done)->
      cond =
        project_id: task.project_id
        status: _enum.TaskStatus.Created

      data = status: _enum.TaskStatus.Canceled
      _entity.task.update cond, data, done
  )

  #保存任务
  queue.push(
    (done)-> _entity.task.save task, done
  )

  _async.waterfall queue, (err)-> cb err

#批量插入任务，检查任务是否存在
bulkInsertTasks = (tasks, cb)->
  index = 0
  _async.whilst(
    -> index < tasks.length
    (
      (done)->
        task = tasks[index++]
        _entity.task.exists hash: task.hash, (err, exists)->
          #存在或者错误都不再继续
          return done err if err or exists
          #保存任务
          insertTask task, (err)-> done err
    ), cb
  )

#分析commit
analysePushEvent = (data)->
  result = []
  for commit in data.commits
    extract = _utils.extractCommandFromGitMessage commit.message
    break if not extract

    #提取分支信息
    branch = data.ref.replace(/^refs\/heads\/(.+)$/i, '$1')

    result.push(
      url: commit.url
      email: commit.author.email
      timestamp: new Date(commit.timestamp).valueOf()
      hash: commit.id
      message: commit.message
      branch: branch
      project_id: -1
      status: _enum.TaskStatus.Created
      repos: data.repository.url
    )

  result

#分析hook，提取符合规则的git，保存到任务队列
exports.execute = (data, cb)->
  tasks = analysePushEvent(data)
  return cb null if tasks.length is 0

  queue = []
  #从bhf上获取git地址对应的项目id
  queue.push(
    (done)->
      _bhfProxy.findProjectWithGit data.repository.url, (err, result)->
        return done err if err

        project_id = (result and result.length > 0 and result[0].id) || -1
        _.map tasks, (task)-> task.project_id = project_id
        done err
  )

  #批量插入任务
  queue.push(
    (done)-> bulkInsertTasks tasks, done
  )

  _async.waterfall queue, (err)-> cb err