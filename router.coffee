#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 6:01 PM
#    Description: 路由配置
_http = require('bijou').http
_ = require 'lodash'

_api = require './biz/api'
_utils = require './utils'
_supervisor = require './biz/supervisor'
_status = require './biz/status'

#git hook的路由
gitHookRoute = (req, res, next)->
  data = req.body
  _api.gitHook data, (err, result)-> _http.responseJSON err, result, res

#获取服务器当前运行的任务，有多少个任务需要执行
hoobotStatusRouter = (req)->
  req.io.respond running: true

#获取所有项目数据
getProjectsRouter = (req)->
  _api.getProject {}, (err, data)-> req.io.respond data

getTasksRouter = (req)->
  client = query: req.data
  _api.getTask client, (err, tasks)-> req.io.respond tasks

#执行指定的任务，仅能在空闲的时候执行任务
runTaskRouter = (req)->
  req.io.respond _supervisor.runTask(req.data.task_id)

#初始货socket事件
initSocketEvent = (app)->
  #实时的日志
  _utils.onRealLog (data)-> app.io.broadcast('realtime', data)

  events = [
    'agent:status'
    'task:start'
    'task:stop'
  ]

  _.map events, (item)->
    ((eventName)->
      _utils.addListener eventName, (data)->
        app.io.broadcast eventName, data
    )(item)


exports.init = (app)->
  initSocketEvent(app)
  #hoobot的当前状态
  app.io.route 'getHoobotStatus', hoobotStatusRouter
  #代理服务器的状态
  app.io.route 'getAgentStatus', (req)-> req.io.respond _status.agentStatus()
  #获取汇总后的信息
  app.io.route 'getProjects', getProjectsRouter
  #获取所有任务
  app.io.route 'getTasks', getTasksRouter
  #获取正在运行的任务
  app.io.route 'getRunningTask', (req)-> req.io.respond _supervisor.runningTask()
  #执行任务
  app.io.route 'runTask', runTaskRouter
  #常规http的路由
  app.post '/api/git/commit', gitHookRoute
  app.get /(\/\w+)?$/, (req, res, next)-> res.sendfile 'static/index.html'