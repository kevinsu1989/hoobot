#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:34 AM
#    Description:

define [
  'ng'
  'utils'
  't!/views.html'
], (_ng, _utils, _template)->
  _ng.module("app.directives", ['app.services', 'app.filters'])

  .directive('timeAgo', ['$filter', '$interval', ($filter, $interval)->
    restrict: 'A'
    replace: false
    link: (scope, element, attrs)->
      updateFn = ->
        element.text $filter('timeAgo')(parseInt(attrs.timeAgo))

      updateFn()
      timer = window.setInterval updateFn, 6000
      scope.$on '$destroy', ()-> window.clearInterval timer
  ])

  #任务列表tmpl-task-list
  .directive('taskList', ['$rootScope', 'SOCKET', ($rootScope, SOCKET)->
    restrict: 'E'
    replace: false
    template: _utils.extractTemplate '#tmpl-task-list', _template
    link: (scope, element, attrs)->
      #加载某个项目下的所有任务
      loadAllTask = (project_id)->
        cond =
          project_id: project_id
          pageSize: 10
          pageIndex: 1

        SOCKET.getTasks cond, (result)->
          scope.tasks = result
          scope.$apply()

      attrs.$observe('projectId', ->
        loadAllTask attrs.projectId if attrs.projectId
      )

      #点击部署
      scope.onClickDeploy = (event, task)->
        return if $rootScope.runningTask
        $rootScope.runningTask = task
        SOCKET.runTask task.id
  ])

  #项目列表
  .directive('projectList', ['SOCKET', (SOCKET)->
    restrict: 'E'
    replace: false
    template: _utils.extractTemplate '#tmpl-project-list', _template
    link: (scope, element, attrs)->
      scope.onClickProjectItem = (event, project)->
        scope.currentProjectId = project.project_id

      SOCKET.allProject (data)->
        scope.projects = data
        scope.currentProjectId = data[0].project_id if data.length > 0
        scope.$apply()
  ])

  #实时的日志
  .directive('realtimeLog', ['SOCKET', (SOCKET)->
    restrict: 'E'
    replace: false
    link: (scope, element, attrs)->

      analyseEvent = (data) ->
        html = ""
        html += data.message
        html

      #渲染服务器返回来的日志
      render = (data) ->
        $current = $("<div />")
        element.append $current
        html = new Date() + ": "
        if typeof (data) is "string"
          html += data
        else
          html += analyseEvent(data)
        $current.html html
        return

      scope.$on 'socket:realtime', (event, data)-> render data
  ])


  .directive('agentStatus', ['$rootScope', 'SOCKET', ($rootScope, SOCKET)->
    restrict: 'A'
    link: (scope, element, attrs)->
      scope.agents = []
      updateAgents = (agents)->
        scope.agents = agents
        scope.$apply()

      #服务器主动推送代理的状态
      $rootScope.$on 'socket:agent:status', (event, agents)-> updateAgents agents

      #获取服务器状态
      SOCKET.agentStatus (agents)-> updateAgents agents
  ])

  #顶部的消息
  .directive('quicklyMessage', ['$rootScope', '$filter', 'SOCKET', ($rootScope, $filter, SOCKET)->
    restrict: 'A'
    link: (scope, element, attrs)->
      defaultMessage = '欢迎使用Hoobot控制台，当前没有任何通知'
      updateMessage = (content, type = 'info')->
        scope.message =
          type: 'info'
          content: content

      updateMessage defaultMessage

      $rootScope.$on 'socket:task:start', (event, task)->
        scope.$apply ()-> updateMessage "执行新的任务 -> #{task.message}"

      $rootScope.$on 'socket:task:stop', (event, task)->
        type = $filter('taskStatusType')(task.status)
        result = $filter('taskStatus')(task.status)
        content = "任务执行完成，执行结果：#{result} -> #{task.message}"
        scope.$apply ()-> updateMessage content, type

      $rootScope.$on 'socket:realtime', (event, data)->
        if data.type in ['command', 'delivery', 'log']
          content =  "#{data.description} -> #{data.task.message}"
          scope.$apply ()-> updateMessage content
  ])