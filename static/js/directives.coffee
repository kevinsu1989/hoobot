#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:34 AM
#    Description:

define [
  'ng'
  'utils'
  't!/views.html'
  'pkg/semantic/semantic.min'
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

      cond = type: 'preview'
      SOCKET.getProjects cond, (data)->
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
#      $stream = element.find('div.custom-stream .custom-content')
#      $streamContainer = element.find('div.custom-stream')
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

#        writeStream(content: text)

      writeStream = (data)->
#        text = if typeof data.content is 'object' then JSON.stringify(data.content)  else data.content
#        html = "<div class='custom-row'>#{text}</div>"
#        $stream.append html

      scope.$on 'socket:realtime', (event, data)->
        scope.running = true
        render data
  ])


  .directive('agentStatus', ['$rootScope', 'SOCKET', ($rootScope, SOCKET)->
    restrict: 'A'
    link: (scope, element, attrs)->
      scope.status = {}
      updateStatus = (event, status)->
        scope.status = status
        scope.$apply()

      #服务器主动推送代理的状态
      $rootScope.$on 'socket:status', updateStatus

      #获取服务器状态
      SOCKET.getHoobotStatus (status)-> updateStatus null, status
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

  .directive('releaseProjectList', ['$rootScope', 'SOCKET', ($rootScope, SOCKET)->
    restrict: 'E'
    replace: true
    template: _utils.extractTemplate '#tmpl-release-project-list', _template
    link: (scope, element, attrs)->

      scope.onClickEdit = (event, project)->
        event.stopPropagation()
        $rootScope.$broadcast 'project:editor:show', project

      scope.onClickRemove = (event, project)->
        event.stopPropagation()
        return if not confirm("您确定要删除这个项目吗？")
        SOCKET.removeProject project.id, (err)-> loadProject()

      #强制刷新标签
      scope.onClickRefresh = (event, project)->
        event.stopPropagation()
        $rootScope.$broadcast 'dimmer:show'
        SOCKET.refreshTag project.id, ->
          loadProject()
          $rootScope.$broadcast 'dimmer:hide'

      #加载项目
      scope.onClickProject = (event, project)->
        event.stopPropagation()
        scope.currentReleaseProjectId = project.id

      loadProject = ()->
        cond = type: 'release'
        SOCKET.getProjects cond, (result)->
          scope.projects = result
          return if not (result and result.length > 0)
          scope.currentReleaseProjectId = result[0].id
          scope.$apply()

      loadProject()

      $rootScope.$on 'project:list:reload', (event)-> loadProject()
  ])

  .directive('releaseProjectEditor', ['$rootScope', 'SOCKET', ($rootScope, SOCKET)->
    restrict: 'A'
    replace: false
    link: (scope, element, attrs)->
      scope.project = {}

      #收到打开编辑器的请求
      scope.$on 'project:editor:show', (event, project)->
        scope.project = project || {}
        element.modal('setting', {
          'closable': false
          onApprove: -> false
        }).modal('show')

      scope.onClickSave = (event)->
        return alert('Token必需添加，否无法获取Tag列表') if not scope.project.token
        return alert('项目名称必需添加') if not scope.project.repos_name
        return alert('仓库地址必需添加') if not scope.project.repos_git

        SOCKET.saveProject scope.project, ()->
          alert('保存成功')
          element.modal('hide')
          $rootScope.$broadcast 'project:list:reload'
          #发送重新加载项目列表的消息
  ])

  #获取发布的tag列表
  .directive('releaseTagList', ['$rootScope', '$state', 'SOCKET', ($rootScope, $state, SOCKET)->
    restrict: 'E'
    replace: true
    template: _utils.extractTemplate('#tmpl-release-tag-list', _template)
    link: (scope, element, attrs)->

      #加载所有标签
      loadTags = (project_id)->
        SOCKET.getTags project_id, (result)->
          scope.tags = result
          scope.$apply()

      scope.onClickDeploy = (event, data)->
        SOCKET.release data, (err, task_id)->
          $state.go 'realtime', task_id: task_id

        #alert("正式部署这个功能还没有做")

      scope.$watch 'currentReleaseProjectId', ()->
        return if not scope.currentReleaseProjectId
        loadTags scope.currentReleaseProjectId
  ])

  .directive('dimmer', [->
    restrict: 'A'
    replace: true
    link: (scope, element, attrs)->
      #显示
      scope.$on 'dimmer:show', (message = 'Processing')->
        element.dimmer('show', {closable: false})

      scope.$on 'dimmer:hide', -> element.dimmer 'hide'
  ])

  #获取后台的实时日志
  .directive('realtimeStream', ['SOCKET', (SOCKET)->
    restrict: 'A'
    link: (scope, element, attrs)->
      scope.$on 'socket:stream', (event, message)->
        element.empty() if element.children().length > 1000
        html = "<div class='custom-stream-row'>#{message}</div>"
        element.append html
#        element.animate({scrollTop: $streamContainer.height()},'slow');
  ])