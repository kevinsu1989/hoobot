#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 4:58 PM
#    Description: clone并build项目

_path = require 'path'
_utils = require '../utils'

#获取代码并签出，不使用pull的原因是避免文件被意外改动pull不成功，直接clone
cloneAndBuild = (task)->
  projectName =  _utils.extractProjectName(task.repos)
  #本地仓库的目录
  reposProjectDir = _utils.reposDireectory projectName
  #构建的目标目录
  buildTarget = _utils.buildDireectory projectName
  _utils.cleanTarget reposProjectDir

  commands = [
    {
      command: "git clone #{task.repos} #{reposProjectDir}"
      description: "从远程clone仓库"
      task: task
    }
    {
      command: "cd #{reposProjectDir} && git checkout #{task.hash} "
      description: "切换到指定hash"
      task: task
    }
    {
      command: "cd #{reposProjectDir} && silky build -o #{buildTarget}"
      description: "用Silky构建项目"
      task: task
    }
  ]

  for item in commands
    result = _utils.execCommand(item)
    return result if not result

  result

#执行构建
exports.execute = (task, cb)->
  success = cloneAndBuild task
  err = if success then null else new Error('Clone或Build项目，请检查日志')
  cb null