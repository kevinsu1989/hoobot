#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 3:19 PM
#    Description:

define [
  'ng'
  '/socket.io/socket.io.js'
], (_ng, _io)->

  _ng.module('app.services', [])
  .factory('SOCKET', ['$rootScope',
      ($rootScope)->
        updateRunningTask = (data)->
          return if data.type isnt 'task'
          switch data.process
            when 'end' then $rootScope.runningTask = null
            when 'stop' then $rootScope.runningTask = data.task

        socket = _io.connect()
        socket.on 'connect', ->
          socket.emit 'ready'

          socket.on 'stream', (data)-> $rootScope.$broadcast 'socket:stream', data
          #服务器主动推送状态信息
          socket.on 'status', (data)-> $rootScope.$broadcast 'socket:status', data
          #实时的日志消息
          socket.on 'realtime', (data)->
            updateRunningTask data
            $rootScope.$broadcast 'socket:realtime', data

        {
          #获取活动的任务
          getActiveTask: (project_id, cb)-> socket.emit 'getActiveTask', project_id: project_id, cb
          #获取代理服务器的状态
          getHoobotStatus: (cb)-> socket.emit 'getHoobotStatus', cb
          #所有的项目
          getPreviewProject: (cb)-> socket.emit 'getPreviewProject', cb
          #获取项目信息
          getProjects: (cond, cb)-> socket.emit 'getProjects', cond,  cb
          #获取所有的任务
          getTasks: (params, cb)->
            socket.emit 'getTasks', params, cb
          saveProject: (data, cb)->
            socket.emit 'saveProject', data, cb
          #执行某条任务
          runTask: (task_id, uuid)->
            data =
              task_id: task_id
              uuid: uuid
            socket.emit 'runTask', data

          #删除某个项目
          removeProject: (project_id, cb)->
            socket.emit 'removeProject', project_id: project_id, cb
          #强制刷新标签
          refreshTag: (project_id, cb)->
            socket.emit 'refreshTag', project_id: project_id, cb
          #获取所有的标签
          getTags: (project_id, cb)->
            socket.emit 'getTags', project_id: project_id, cb
          #发布到SVN
          release: (data, cb)->
            socket.emit 'release', data, cb
        }
  ])
