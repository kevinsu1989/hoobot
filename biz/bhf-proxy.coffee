#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/6/15 2:45 PM
#    Description: 与bhf交互的代理

_transport = require './transport'
_config = require '../config'
_token = null
_tokenRequestCounter = 0

#请求token
requestToken = (cb)->
  exports.requestBHF 'account/token', 'post', _config.bhf.acccount, (err, res, result)->
    _tokenRequestCounter++
    _token = result.token
    cb err, res, result

#获取所有的项目列有
exports.getAllProject = ()->
  params = pageSize: 9999
  @requestBHF 'project', 'get', params, null, (err, res, result)->
    console.log result

#根据git地址，查找对应的项目
exports.findProjectWithGit = (git, cb)->
  params = git: git
  @requestBHF 'project/git-map', 'get', params, null, (err, res, result)-> cb err, result

#处理与BHF的交互
exports.requestBHF = (api, method, data, options, cb)->
  args = if 1 <= arguments.length then [].slice.call(arguments, 0) else []
  if typeof(options) is 'function' and not cb
    cb = options
    options = {}

  options = options || {}
  options.method = method
  options.uri = "#{_config.bhf.baseUrl}#{api}"
  options.json = true
  options.headers = {
    'x-token': _token
  }

  if /^(post|put)$/.test method
    options.body = data
  else
    options.qs = data

  _transport.request options, (err, res, result)->
    return cb err if err
    #返回用户未验证，且尝试的次数小于5次
    if res.statusCode is 401 and _tokenRequestCounter < 5
      requestToken (err)->
        exports.requestBHF.apply exports, args
    else
      cb err, res, result