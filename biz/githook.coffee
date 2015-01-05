#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:54 PM
#    Description: 分析并处理git hooks
_ = require 'lodash'
_entity = require '../entity'
_transport = require './transport'
_utils = require '../utils'
_async = require 'async'

#保存任务信息
saveTasks = (data, tasks, cb)->
  queue = []
  #根据项目的url，获取对应的id
  queue.push(
    (done)->
      params = git: data.repository.url
      #从bhf上获取git地址对应的项目id
      _transport.getBHF 'project/git-map', params, (err, result)->
        return done err if err or result.length is 0
        project_id = result[0].project_id
        _.map tasks, (task)-> task.project_id = project_id
        done err
  )

  #插入任务
  queue.push(
    (done)->
      _entity.task.insert tasks, (err)-> done err
  )

  _async.waterfall queue, cb

#分析commit
analysePushEvent = (data)->
  result = []
  for commit in data.commits
    extract = _utils.extractCommandFromGitMessage commit.message
    break if not extract

    #提取分支信息
    branch = /^refs\/heads\/(.+)$/i.replace(data.ref, '$1')

    result.push(
      url: commit.url
      email: commit.author.email
      timestamp: commit.timestamp
      hash: commit.id
      message: commit.message
      branch: branch
    )

  result

#分析hook，提取符合规则的git，保存到任务队列
exports.execute = (data, cb)->
  tasks = analysePushEvent(data)
  return cb null if tasks.length is 0

  saveTasks tasks, cb