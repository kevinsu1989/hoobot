#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 4:58 PM
#    Description: clone并build项目

_path = require 'path'
_async = require 'async'
_fs = require 'fs-extra'

_utils = require '../utils'

#获取代码并签出，不使用pull的原因是避免文件被意外改动pull不成功，直接clone
cloneAndBuild = (task, cb)->
  projectName =  _utils.extractProjectName(task.repos)
  #本地仓库的目录
  reposProjectDir = _utils.reposDireectory projectName
  #构建的目标目录
  buildTarget = _utils.buildDireectory projectName
#  _utils.cleanTarget reposProjectDir

  #检查本地仓库是否存在，如果存在，则使用fetch
  if _fs.existsSync reposProjectDir
    console.log reposProjectDir
    items = [{
        command: "cd #{reposProjectDir} && git fetch origin"
        description: "拉取远程仓库"
        task: task
      }]
  else
    items = [{
      command: "git clone #{task.repos} #{reposProjectDir}"
      description: "从远程clone仓库"
      task: task
    }]

  items = items.concat [
    {
      command: "cd #{reposProjectDir} &&git checkout #{task.hash}"
      description: "切换分支到#{task.hash}"
      task: task
    }
    {
      command: "cd #{reposProjectDir} && silky build -o #{buildTarget}"
      description: "用Silky构建项目"
      task: task
    }
  ]

  index = 0
  _async.whilst(
    -> index < items.length
    ((done)->
      item = items[index++]
      data =
        type: 'log'
        description: "正在#{item.description}..."
        task: task

      _utils.emitRealLog data
      _utils.execCommand item, done
    ), cb
  )

#执行构建
exports.execute = (task, cb)->
  cloneAndBuild task, cb