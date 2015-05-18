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

_utils = require './utils'
_deploy = require './biz/deploy'
_config = require './config'

_app.configure(->
  uploadDir = _path.resolve __dirname, _config.uploadTemporary
  _fs.ensureDirSync uploadDir


  console.log __dirname
  _app.use(require('coffee-middleware')({
    src: __dirname + '/static'
    compress: true
  }))

  _app.use(require('less-middleware')(__dirname + '/static'))
  _app.use(_express.static(__dirname + '/static'))
  _app.use(_express.methodOverride())
  _app.use(_express.bodyParser(
    uploadDir: uploadDir
    limit: '1024mb'
    keepExtensions: true
  ))
  _app.set 'port', _config.port.agent || 1518
)



_app.get('/api/agent', (req, res, next)->
  _fs.readdir _config.previewDirectory, (err, result)->
    _http.responseJSON err, result, res
)

_app.delete('/api/agent', (req, res, next)->
  directive =  _config.previewDirectory + '/' +req.body.dir
  if _fs.existsSync directive
    _fs.removeSync directive
    return res.end 'success'
  res.end 'false'
)

#接收并处理主服务器提交过来的分发内容
_app.post('/api/agent', (req, res, next)->
  _utils.emitRealLog(
    message: '代理服务器收到分发请求'
    body: req.body
    type: 'agent'
  )

  attachment = req.files.attachment
  projectName = req.body.project_name || req.body.projectName || _utils.extractProjectName(task?.repos) || 'unknown'

  _deploy.execute attachment, projectName, req.body, (err)->
    message = '代理服务器部署完成'
    _utils.emitRealLog(
      message: message
      body: req.body
      type: 'agent'
      error: err
    )

    # console.log message
    result = success: !err
    _http.responseJSON err, result, res
)

#供服务器询询用
_app.get('/are-you-working', (req, res, next)->
  data =
    version: require('./package.json').version
    previewDirectory: _config.previewDirectory
  _http.responseJSON null, data, res
)
_app.listen _app.get('port')
# console.log "Port: #{_app.get 'port'}, Now: #{new Date()}"

