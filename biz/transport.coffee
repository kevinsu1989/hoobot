#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:32 PM
#    Description: 处理http请求相关

_url = require 'url'
_http = require 'http'
_qs = require 'querystring'
_request = require 'request'
_fs = require 'fs-extra'
_ = require 'lodash'

_utils = require '../utils'
_config = require '../config'

#分发tarboll到目标服务器
exports.deliverProject = (tarfile, task, cb)->
  formData = _.extend {}, task
  formData.attachment = _fs.createReadStream tarfile

  options =
    url: task.delivery_server
    method: 'POST'
    json: true
    formData: formData

  exports.request options, (err, res, body)->
    return cb err if err
    if res.statusCode isnt 200
      err = new Error('代理服务器返回状态码不正确，请检查')
      return cb err

    #检查接收服务器，是否返回了success: true
    cb err, body.success

#请求数据
#exports.get = (url, params, options, cb)->
#  if typeof params is 'function'
#    cb = params
#    params = {}
#    options = {}
#  else if typeof options is 'function'
#    cb = options
#    options = {}
#
#  options = options || {}
#
#  url += "?#{_qs.stringify(params)}" if params
#
#
#  options.url = url
#  _request.get options, (err, res, body)->
#    return cb err if err
#    return cb err, undefined if not body
#    result = JSON.stringify body
#    cb err, result

##请求BHF的token
#exports.requestBHFToken = ()->
#  exports.requestBHF 'account/token', 'post', _config.bhf.acccount, (err, res, result)->
#    console.log result
#
##处理与BHF的交互
#exports.requestBHF = (api, method, data, options, cb)->
#  if typeof(options) is 'function' and not cb
#    cb = options
#    options = {}
#
#  #options = options || {}
#  options.method = method
#  options.uri = "#{_config.bhf.baseUrl}#{api}"
#
#  if /^(post|put)$/.test method
#    options.body = data
#    options.json = true
#  else
#    options.qs = data
#
#  exports.request options, cb

#请求服务器
exports.request = (options, cb)->
  defaultOptions =
    method: 'GET'

  ops = _.extend defaultOptions, options
  _request ops, cb