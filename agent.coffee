#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/7/15 10:46 AM
#    Description:

_express = require 'express.io'
_http = require 'http'
_app = _express()
_path = require 'path'
_app.http().io()
_fs = require 'fs-extra'
_http = require('bijou').http

require 'shelljs/global'
require 'colors'

_deploy = require './biz/deploy'
_config = require './config'

_app.configure(->
  uploadDir = _path.resolve __dirname, _config.uploadTemporary
  console.log uploadDir
  _fs.ensureDirSync uploadDir

  _app.use(_express.methodOverride())
  _app.use(_express.bodyParser(
    uploadDir: uploadDir
    limit: '1024mb'
    keepExtensions: true
  ))
  _app.set 'port', _config.port.agent || 1518
)

#接收并处理主服务器提交过来的分发内容
_app.post('/agent', (req, res, next)->
  attachment = req.files.attachment

  _deploy.execute attachment, req.body, (err)->
    result = success: !err
    _http.responseJSON err, result, res
)

_app.listen _app.get 'port'
console.log "Port: #{_app.get 'port'}, Now: #{new Date()}"

