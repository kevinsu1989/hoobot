#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:06 AM
#    Description: 路由

"use strict"
define [
  "ng"
  "app"
  'utils'
  't!/views.html'
], (_ng, _app, _utils, _template) ->

  _app.config(['$locationProvider', '$stateProvider', '$urlRouterProvider',
    ($locationProvider, $stateProvider) ->
      $locationProvider.html5Mode enabled: true, requireBase: false

      $stateProvider
      .state('home',
        url: '/'
        template: _utils.extractTemplate('#tmpl-projects', _template)
        controller: 'projectsController'
      )

      .state('agents',
        url: '/agent'
        template: _utils.extractTemplate('#tmpl-agent-list', _template)
        controller: 'agentController'
      )

      .state('realtime',
        url: '/realtime?task_id'
        template: _utils.extractTemplate('#tmpl-realtime', _template)
        controller: 'realtimeController'
      )

      .state('release',
        url: '/release'
        template: _utils.extractTemplate('#tmpl-release', _template)
        controller: 'releaseProjectListController'
      )
  ])