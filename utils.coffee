#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 5:08 PM
#    Description:
_path = require 'path'
_fs = require 'fs-extra'
_async = require 'async'
_events = require 'events'

_config = require './config'

_realEvent = new _events.EventEmitter()

#触发事件
exports.emitEvent = (name, args...)->
  _realEvent.emit.apply _realEvent, [name].concat(args)

#监听事件
exports.addListener = (event, listener)-> _realEvent.addListener event, listener

#监听
exports.removeListener = (event, listener)-> _realEvent.removeListener event, listener

exports.onRealLog = (cb)->
  _realEvent.addListener 'realLog', (log)-> cb?(log)

#触发实时的日志
exports.emitRealLog = (data)-> _realEvent.emit 'realLog', data

#移除扩展名
exports.removeExt = (filename)-> filename.replace /\.\w+/, ''

#从仓库名称中，提取项目的名称
exports.extractProjectName = (repos)->
  return '' if not repos
  repos.replace(/.+\/(.+)\.git$/, '$1')

#临时工作目录
exports.tempDirectory = -> _path.join(exports.homeDirectory(), '.hoobot')

#仓库的工作目录
exports.reposDireectory = (projectName)-> _path.join(exports.tempDirectory(), 'repos', projectName)

#silky的构建目录
exports.buildDireectory = (projectName)-> _path.join(exports.tempDirectory(), 'build', projectName)

#用于存放打包的目录
exports.projectPackagePath = (projectName)-> _path.join(exports.tempDirectory(), 'tar', projectName + '.tar')

#获取项目的工作目录
exports.projectDirectory = ->
  _path.resolve __dirname, _config.projectDirectory

#获取svn的工作目录
exports.svnDirectory = ->
  _path.resolve __dirname, _config.svnDirectory

#用户的home目录
exports.homeDirectory = ->
  process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME']

#如果目录存在，则清除
exports.cleanTarget = (target)->
  return if not _fs.existsSync target
  _fs.removeSync target

#批量执行命令，遇到问题即返回
exports.execCommand = (command, cb)->
  exec command.command, async: true, (err)->
    data =
      command: command.command
      success: !!err
      type: 'command'
      task: command.task
      description: command.description

    #推送实时的日志
    exports.emitRealLog data
    cb err, true

#从git commit message中提取指令
exports.extractCommandFromGitMessage = (message)->
  pattern = /#(p|push|preview)\-(.+?)\s/i
  return if not message
  matches = message.match pattern
  return if not matches
  return type: matches[1], target: matches[2]