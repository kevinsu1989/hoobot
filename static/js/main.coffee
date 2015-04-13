#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 10:53 AM
#    Description:

require.config
  baseUrl: '/js'
  paths:
    ng: 'vendor/angular'
    v: 'vendor'
    jquery: 'vendor/jquery'
    _: 'vendor/lodash'
    t: 'vendor/require.text'
    moment: 'vendor/moment'
    utils: 'utils'
    pkg:'/package'
    'semantic': '/package/semantic/semantic.min'
  shim:
#    'v/jquery.noty': 'jquery'
    ng:
      exports : 'angular'
      deps: ['semantic']
#    'v/jquery.transit': ['jquery', '_']
    app: ['ng', 'jquery']
    'semantic': ['jquery']

window.name = "NG_DEFER_BOOTSTRAP!";

require [
  "ng"
  "app"
  "routes"
], (_ng, _app) ->
  _ng.element().ready -> _ng.resumeBootstrap [_app.name]