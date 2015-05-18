#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 6:01 PM
#    Description: 路由配置
_http = require('bijou').http
_ = require 'lodash'

_api = require './biz/api'
_utils = require './utils'
_fs = require 'fs-extra'
_config = require './config'
_supervisor = require './biz/supervisor'
_status = require './biz/status'
_tags = require './biz/tags'




#git hook的路由
gitHookRoute = (req, res, next)->
  data = req.body
  _api.gitHook data, (err, result)-> _http.responseJSON err, result, res

saveTask = (req, res, next)->
  data = req.body
  _api.saveTask data, (err, result)-> _http.responseJSON err, result, res

getAgent = (req, res, next)->
  _fs.readdir _config.previewDirectory, (err, result)->
    _http.responseJSON err, result, res
  
deleteAgent = (req, res, next)->
  directive =  _config.previewDirectory + '/' +req.body.dir
  if _fs.existsSync directive
    _fs.removeSync directive
    return res.end 'success'
  res.end 'false'
  

#获取服务器当前运行的任务，有多少个任务需要执行
hoobotStatusRouter = (req)->
  req.io.respond running: true

#获取所有项目数据
getPreviewProjectRouter = (req)->
  _api.getPreviewProject (err, data)-> req.io.respond data

getTasksRouter = (req)->
  _api.getTask req.data, (err, tasks)-> req.io.respond tasks

#执行指定的任务，仅能在空闲的时候执行任务
runTaskRouter = (req)->
  req.io.respond _supervisor.runTask(req.data.task_id, req.data.uuid)

#发布
releaseRouter = (req)->
  _api.release req.data, (err, task_id)->
    req.io.respond err and err.toJSON(), task_id

#获取所有的gituser
getGitUsersRouter = (req)->
  _api.getGitUsers (err, result)->
    req.io.respond result

#获取所有的项目
getProjectsRouter = (req)->
  _api.getProject req.data, (err, result )->
    req.io.respond result

saveProjectRouter = (req)->
  _api.saveProject req.data, (err, result)->
    req.io.respond result

#获取所有标签
getTagsRouter = (req)->
  req.io.respond _tags.getTags(req.data.project_id)

refreshTagRouter = (req)->
  _tags.refreshTag req.data.project_id, (err, result)->
    req.io.respond err, result

#删除项目的路由
removeProjectRouter = (req)->
  _api.removeProject req.data.project_id, (err)->
    req.io.respond()

getActiveTaskRouter = (req)->
  _api.getActiveTask req.data.project_id, (err, result)->
    req.io.respond(err, result)

#加解锁任务锁
changeActiveTaskLockRouter = (req)->
  _api.changeActiveTaskLock req.data.task_id, req.data.is_lock, (err)->
    req.io.respond()

#初始货socket事件
initSocketEvent = (app)->
  #实时的日志
  _utils.onRealLog (data)-> app.io.broadcast('realtime', data)

  events = [
    'agent:status'
    'task:start'
    'task:stop'
    'stream'
  ]

  _.map events, (item)->
    ((eventName)->
      _utils.addListener eventName, (data)->
        app.io.broadcast eventName, data
    )(item)


exports.init = (app)->

  initSocketEvent(app)
  #hoobot的当前状态
  app.io.route 'getHoobotStatus', (req)-> req.io.respond _status.get()
  #代理服务器的状态
#  app.io.route 'getAgentStatus', (req)-> req.io.respond _status.agentStatus()
  #获取汇总后的信息
  app.io.route 'getPreviewProject', getPreviewProjectRouter
  #获取所有任务
  app.io.route 'getTasks', getTasksRouter
  #获取正在运行的任务
  app.io.route 'getRunningTask', (req)-> req.io.respond _supervisor.runningTask()
  #执行任务
  app.io.route 'runTask', runTaskRouter
  app.io.route 'getProjects', getProjectsRouter
  app.io.route 'getGitUsers', getGitUsersRouter
  app.io.route 'saveProject', saveProjectRouter
  app.io.route 'getTags', getTagsRouter
  app.io.route 'refreshTag', refreshTagRouter
  app.io.route 'removeProject', removeProjectRouter
  app.io.route 'release', releaseRouter
  app.io.route 'getActiveTask', getActiveTaskRouter
  app.io.route 'changeActiveTaskLock', changeActiveTaskLockRouter

  #常规http的路由
  app.post '/api/git/commit', gitHookRoute
  app.post '/api/task', saveTask
  app.get '/api/agent', getAgent
  app.delete '/api/agent', deleteAgent
  app.get /(\/\w+)?$/, (req, res, next)-> res.sendfile 'static/index.html'



#  _supervisor.runTask 20423