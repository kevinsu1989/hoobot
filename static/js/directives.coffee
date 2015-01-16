#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:34 AM
#    Description:

define [
  'ng'
  'utils'
  't!/views.html'
  'pkg/semantic/semantic'
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
  .directive('taskList', ['$rootScope', '$state', 'SOCKET', ($rootScope, $state, SOCKET)->
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
      scope.onClickDeploy = (event, task, uuid)->
        return if $rootScope.runningTask
        $rootScope.runningTask = task

        $state.go 'realtime', task_id: task.id
        SOCKET.runTask task.id, uuid
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
  .directive('realtimeLog', ['$state', 'SOCKET', ($state, SOCKET)->
    restrict: 'A'
    replace: false
    link: (scope, element, attrs)->
      $overview = element.find('div.custom-overview .custom-content')
      $stream = element.find('div.custom-stream .custom-content')
      $streamContainer = element.find('div.custom-stream')
      scope.running = false

      #渲染服务器返回来的日志
      render = (data) ->
        $current = $("<div />")
        $overview.append $current
        text = if typeof (data) is "string" then data else data.description
        $current.html "#{new Date()}: #{text}"
        #发生错误
        if data.type is 'task' and data.process is 'end' and not data.success
          $overview.css 'color', 'red'

        writeStream(content: text)

      writeStream = (data)->
        text = if typeof data.content is 'object' then JSON.stringify(data.content)  else data.content
        html = "<div class='custom-row'>#{text}</div>"
        $stream.append html

      scope.$on 'socket:realtime', (event, data)->
        scope.running = true
        render data

      scope.$on 'socket:stream', (event, data)->
        text = if typeof data.content is 'object' then JSON.stringify(data.content)  else data.content
        html = "<div class='custom-row'>#{text}</div>"
        $stream.append html
        $stream.animate({scrollTop: $streamContainer.height()},'slow');
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

      scope.onClickClose = ()->
        element.animate({marginTop: "-#{element.outerHeight()}px"})
        return

      $rootScope.$on 'socket:realtime', (event, data)->
        if data.type in ['command', 'delivery', 'log']
          content =  "#{data.description} -> #{data.task.message}"
          scope.$apply ()-> updateMessage content
  ])

  .directive('deployAgentDropdown', ['$rootScope', '$filter', 'SOCKET',
    ($rootScope, $filter, SOCKET)->
      restrict: 'E'
      template: _utils.extractTemplate '#tmpl-deploy-agent-dropdown', _template
      link: (scope, element, attrs)->

  ])

  .directive('dropdownAction', [->
    restrict: 'A'
    link: (scope, element, attrs)->
      element.dropdown()
  ])