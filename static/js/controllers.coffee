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
#      $scope.status = {}
#      updateStatus = (event, status)->
#        $scope.status = status
#        $scope.$apply()
#
#      #服务器主动推送代理的状态
#      $rootScope.$on 'socket:status', updateStatus
#
#      #获取服务器状态
#      SOCKET.getHoobotStatus (status)-> updateStatus null, status
  ])

  .controller('projectsController', ['$rootScope', '$scope', 'SOCKET',
    ($rootScope, $scope, SOCKET)->
      $rootScope.activeMenu = 'task'
  ])

  .controller('realtimeController', ['$rootScope', '$scope', 'SOCKET',
    ($rootScope, $scope, SOCKET)->
      $rootScope.activeMenu = 'realtime'
  ])

  .controller('releaseProjectListController', ['$rootScope', '$scope', 'SOCKET',
      ($rootScope, $scope, SOCKET)->
        $rootScope.activeMenu = 'release'
  ])

  .controller('classifyController', ['$rootScope', '$scope', 'SOCKET',
      ($rootScope, $scope, SOCKET)->
        $rootScope.activeMenu = 'classify'
  ])