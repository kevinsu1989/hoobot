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
          console.log data.process
          switch data.process
            when 'end' then $rootScope.runningTask = null
            when 'stop' then $rootScope.runningTask = data.task

        socket = _io.connect()
        socket.on 'connect', ->
          socket.emit 'ready'

          socket.on 'stream', (data)-> $rootScope.$broadcast 'socket:stream', data
          #服务器主动推送状态信息
          socket.on 'agent:status', (data)-> $rootScope.$broadcast 'socket:agent:status', data
          #实时的日志消息
          socket.on 'realtime', (data)->
            updateRunningTask data
            $rootScope.$broadcast 'socket:realtime', data

        {
          #获取代理服务器的状态
          agentStatus: (cb)-> socket.emit 'getAgentStatus', cb
          #所有的项目
          allProject: (cb)-> socket.emit 'getProjects', cb
          #获取所有的任务
          getTasks: (params, cb)->
            socket.emit 'getTasks', params, cb
          #执行某条任务
          runTask: (task_id, uuid)->
            data =
              task_id: task_id
              uuid: uuid
            socket.emit 'runTask', data
        }
  ])
