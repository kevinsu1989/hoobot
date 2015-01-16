#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 9:25 AM
#    Description: 部署来自前build服务器的代码

_path = require 'path'
_utils = require '../utils'
_fs = require 'fs-extra'

#部署从分发服务器上传过来的项目，需要解包
exports.execute = (attachment, task, cb)->
  tarFile = attachment.path
  projectName = _utils.extractProjectName task.repos
  targetDir = _path.join _utils.projectDirectory(), projectName
  _fs.ensureDirSync targetDir

  command = {
    command: "tar xf #{tarFile} -C #{targetDir}"
    description: "解开tar包到目标项目"
    task: task
  }

  _utils.execCommand command, (err)->
    #不管有没有成功，都要删除临时文件，如果没有成功，返回错误信息到分发服务器再行处理
    _fs.unlinkSync tarFile
    cb err