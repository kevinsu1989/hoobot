#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 9:25 AM
#    Description: 部署来自前build服务器的代码

_path = require 'path'
_utils = require '../utils'
_fs = require 'fs-extra'
_config = require '../config'
_ = require 'lodash'

#release，还需要复制css/image/js三个目录，同时生成version.json并写入tag
copyToSync = (projectName, sourceDir, task)->
  version =
    tag: task.tag
    hash: task.hash
    url: task.url
    timestamp: new Date().toString()

  #获取同步目录
  syncDir = _path.join _config.syncDirectory, projectName
  _fs.ensureDirSync syncDir

  #写入版本数据
  versionFile = _path.join syncDir, 'version.json'
  _fs.writeJSONFileSync versionFile, version
  console.log version, versionFile

  #复制
  _.map ['image', 'js', 'css'], (folder)->
    source = _path.join sourceDir, folder
    target = _path.join syncDir, folder

    console.log source, target
    #源文件夹不存在
    return if not _fs.existsSync(source)

    #删除目标目录
    _fs.removeSync target if _fs.existsSync target
    #复制到目录
    _fs.copySync source, target


#部署从分发服务器上传过来的项目，需要解包
exports.execute = (attachment, projectName, task, cb)->
  return cb null if not task

  tarFile = attachment.path
  targetDir = _path.join _utils.previewDirectory(), projectName
  _fs.ensureDirSync targetDir

  command = {
    command: "tar xf #{tarFile} -C #{targetDir}"
    description: "解开tar包到目标项目"
    task: task
  }


  _utils.execCommandWithTask command, (err)->
    #不管有没有成功，都要删除临时文件，如果没有成功，返回错误信息到分发服务器再行处理
    _fs.unlinkSync tarFile
    #如果是release，则复制文件到sync文件夹
    copyToSync projectName, targetDir, task if task.type is 'release'

    cb err