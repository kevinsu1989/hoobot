#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:34 AM
#    Description:

define [
  'ng'
], (_ng)->
  _ng.module("app.controllers", ['app.services'])
  .controller('homeController', ['SOCKET', (SOCKET)->

  ])

  .controller('agentController', ['$rootScope', '$scope', 'SOCKET',
    ($rootScope, $scope, SOCKET)->
      $rootScope.activeMenu = 'agent'
      $scope.agents = []

      updateAgents = (agents)->
        $scope.agents = agents
        $scope.$apply()

      #服务器主动推送代理的状态
      $rootScope.$on 'socket:agent:status', (event, agents)-> updateAgents agents

      #获取服务器状态
      SOCKET.agentStatus (agents)-> updateAgents agents
  ])

  .controller('projectsController', ['$rootScope', '$scope', 'SOCKET',
    ($rootScope, $scope, SOCKET)->
      $rootScope.activeMenu = 'task'
  ])

  .controller('realtimeController', ['$rootScope', '$scope', 'SOCKET',
    ($rootScope, $scope, SOCKET)->
      $rootScope.activeMenu = 'realtime'
  ])