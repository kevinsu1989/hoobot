#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 9:25 AM
#    Description: 部署来自前build服务器的代码

_path = require 'path'
_utils = require '../utils'
_fs = require 'fs-extra'
_config = require '../config'
_ = require 'lodash'

#写入version.json
writeVersionFile = (target, data)->
  return if not _fs.existsSync target
  #写入版本数据
  versionFile = _path.join target, 'version.json'
  _fs.writeJSONFileSync versionFile, data

#复制项目到sync目录
copyToSync = (projectName, sourceDir, task, isSpecialSubject, isPlayerSubject)->
  #是否为hone项目
  isHoney =  /^honey(\-2\.0)?$/i.test projectName
  projectName = 'honey-2.0' if isHoney

  versionData =
    project: projectName
    tag: task.tag
    hash: task.hash
    url: task.url
    timestamp: new Date().toString()

  #专题，有子文件夹
  if isSpecialSubject
    syncBaseDir = _path.join _config.syncDirectory, 'zt'
    syncDir = _path.join syncBaseDir, projectName
  else if isPlayerSubject
    syncBaseDir = _path.join _config.syncDirectory, 'player'
    syncDir = _path.join syncBaseDir, projectName
  else
    syncDir = syncBaseDir = _path.join _config.syncDirectory, projectName

  #删除同步目录
  _fs.removeSync syncDir
  #确定文件夹存在
  _fs.ensureDirSync syncDir

  #将版本信息写到syncBaseDir中，因为专题会多出一级项目来
  writeVersionFile syncBaseDir, versionData

  #honey直接复制就可以了
  return _fs.copySync sourceDir, syncDir if isHoney
  #非honey项目，由copyNormalProjectToSync 处理
  copyNormalProjectToSync syncDir, sourceDir
  #分别写入version的文件到js/img/css目录
  _.map ['image', 'css', 'js'], (folder)->
    target = _path.join syncDir, folder
    writeVersionFile target, versionData

#release，还需要复制css/image/js三个目录，同时生成version.json并写入tag
copyNormalProjectToSync = (syncDir, sourceDir)->
  #复制
  _.map ['image', 'js', 'css', 'template'], (folder)->
    source = _path.join sourceDir, folder
    target = _path.join syncDir, folder
    #folder.replace('template', 'html')

    #源文件夹不存在
    return if not _fs.existsSync(source)

    #删除目标目录
    _fs.removeSync target if _fs.existsSync target
    #复制到目录
    _fs.copySync source, target


#部署从分发服务器上传过来的项目，需要解包
exports.execute = (attachment, projectName, task, cb)->
  return cb null if not task

  #是否为专题
  isSpecialSubject = /^zt\-/.test projectName
  #是否为专题
  isPlayerSubject = /^player/.test projectName

  tarFile = attachment.path

  #专题则创建在子文件夹中
  targetDir = if isSpecialSubject
    _path.join _utils.previewDirectory(), 'zt', projectName
  else
    _path.join _utils.previewDirectory(), projectName

  _fs.removeSync targetDir
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
    copyToSync projectName, targetDir, task, isSpecialSubject, isPlayerSubject if task.type is 'release'

    # if isPlayerSubject
    #   filePath = _path.join _utils.previewDirectory(), 'player', 'version1.json'
    #   data = "
    #     {
    #       'project':'#{projectName}',
    #       'tag':'',
    #       'hash':'',
    #       'timestamp':'#{new Date()}'

    #     }
    #   "
    #   _fs.writeFileSync filePath, data, {encoding:'utf-8'}


    cb err

