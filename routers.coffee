#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 12/29/14 6:01 PM
#    Description: 路由配置

module.exports = [
  {
    path: 'git/commit'
    biz: 'api'
    methods: post: 'gitHook', delete: 0, patch: 0, put: 0
  }
  {
    path: 'delivery'
    biz: 'api'
    methods: post: 'postDelivery'
  }
]