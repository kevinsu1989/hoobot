#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 11:29 AM
#    Description:
'use strict'

define [
  'ng'
  'v/ui-router'
  './services'
  './filters'
  './directives'
  './controllers'
], (_ng) ->
  _ng.module 'app', [
    'app.filters'
    'app.directives'
    'app.controllers'
    'ui.router'
  ]