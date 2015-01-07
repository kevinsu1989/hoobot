#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:04 PM
#    Description: 分发到目标服务器
_path = require 'path'
_fs = require 'fs-extra'

_utils = require '../utils'
_transport = require './transport'

#远程分发
deliverProject = (source, projectName, task, cb)->
  tarFile = _utils.projectPackagePath projectName
  #确保文件夹存在
  _fs.ensureDirSync _path.dirname(tarFile)

  #打包文件
  command = {
    command: "cd #{source} && tar -cf #{tarFile} ."
    description: "对文件进行打包"
    task: task
  }
  success = _utils.execCommand command
  return cb new Error('文件打包失败') if not success

  #分发到服务器
  _transport.deliverProject tarFile, task, cb

exports.execute = (task, cb)->
  projectName = _utils.extractProjectName task.repos
  source = _utils.buildDireectory projectName
  deliverProject source, projectName, task, cb