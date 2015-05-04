#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/21/15 9:38 AM
#    Description: 发布项目到svn目录
#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:04 PM
#    Description: 分发到目标服务器
_path = require 'path'
_fs = require 'fs-extra'
_utils = require '../utils'

exports.execute = (task, cb)->
  projectName = _utils.extractProjectName task.repos
  source = _utils.buildDireectory projectName
  target = _utils.svnDirectory projectName

  list = []
  list.push(
    {
      command: "cd #{target} && ls | grep -v .svn | xargs rm -rf"
      description: "在svn目标目录中，除.svn以外的文件"
      task: task
    }
  )

  list.push(
    {
      command: "cp -r #{source}/* #{target}"
      description: "复制文件到svn目标目录中"
      task: task
    }
  )


  list.push(
    {
      command: "cd #{target} && svn up && svn st | awk '{if ( $1 == \"?\") { print $2} else { print \".\"}}' | xargs svn add"
      description: "添加到svn中"
      task: task
    }
  )

  list.push(
    {
      command: "cd #{target} && svn ci -m 'add #{task.hash}'"
      description: "提交svn"
      task: task
    }
  )

  _utils.execCommandsWithTask list, cb