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
insertOrUpdateTask = exports.insertOrUpdateTask = (task, cb)->
  queue = []
    # 一个项目下，只能有一个活动的任务存在
  # 相同项目、目标、类型不能重复
  queue.push(
    (done)->
      cond =
        project_id: task.project_id
        status: _enum.TaskStatus.Created
        target: task.target
        type: task.type

      data = status: _enum.TaskStatus.Canceled
      _entity.task.update cond, data, done
  )

  #根据hash检查相同任务是否已经存在
  queue.push(
    (done)->
      cond =
        project_id: task.project_id
        target: task.target
        type: task.type

      _entity.task.findOne cond, (err, result)->
        return done err if err

        console.log cond, result
        #如果存在则更新
        if result?.id
          _entity.task.updateById result.id, task, done
        else
          _entity.task.save task, done
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
        cond =
          hash: task.hash
          type: 'preview'

        _entity.task.exists cond, (err, exists)->
          #存在或者错误都不再继续
          return done err if err or exists

          task.status = _enum.TaskStatus.Created
          #保存任务
          insertOrUpdateTask task, (err)-> done err
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
      type: 'preview'
      target: extract.target
      url: commit.url
      email: commit.author.email
      timestamp: new Date(commit.timestamp).valueOf()
      hash: commit.id
      message: commit.message
      branch: branch
      project_id: -1
      status: _enum.TaskStatus.Created
      repos: data.repository.url
      failure_counter: 0
    )

  result


#分析hook，提取符合规则的git，保存到任务队列
exports.execute = (data, cb)->
  tasks = analysePushEvent(data)
  return cb null if tasks.length is 0

  project_id = 0
  queue = []

  #获取对应的项目id
  queue.push(
    (done)->
      cond = repos_git: data.repository.url
      _entity.project.findOne cond, (err, result)->
        return done err if err
        project_id = result?.id
        done err
  )

  #根据git地址，获取对应的项目，如果没有项目存在，则插入新的项目
  queue.push(
    (done)->
      return done null if project_id

      projectData =
        repos_git: data.repository.url
        repos_url: data.repository.homepage
        timestamp: new Date().valueOf()
        repos_name: _utils.extractProjectName data.repository.url

      _entity.project.save projectData, (err, id)->
        project_id = id
        done err
  )

  #批量插入任务
  queue.push(
    (done)->
      _.map tasks, (task)-> task.project_id = project_id
      bulkInsertTasks tasks, done
  )

  _async.waterfall queue, (err)-> cb err, tasks.length