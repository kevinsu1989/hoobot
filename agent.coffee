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
_async = require 'async'
_http = require('bijou').http
require 'shelljs/global'
require 'colors'

_utils = require './utils'
_deploy = require './biz/deploy'
_config = require './config'

_app.configure(->
  uploadDir = _path.resolve __dirname, _config.uploadTemporary
  _fs.ensureDirSync uploadDir

  _app.use(require('coffee-middleware')({
    src: __dirname + '/static'
    compress: true
  }))

  _app.use(require('less-middleware')(__dirname + '/static'))
  # _app.use(_express.static(__dirname + '/static'))
  _app.use(_express.methodOverride())
  _app.use(_express.bodyParser(
    uploadDir: uploadDir
    limit: '1024mb'
    keepExtensions: true
  ))
  _app.set 'port', _config.port.agent || 1518
)



_app.get('/api/agent', (req, res, next)->
  _fs.readdir _config.previewDirectory, (err, dirs)->
    data = []
    locked = []
    for i in [0...dirs.length]
      data.push({name: dirs[i], locked: false})
      _fs.exists _config.previewDirectory + "/" + dirs[i] + "/.lock", (result)->
        locked.push result
        if locked.length is dirs.length
          for i in [0...data.length]
            data[i].locked = locked[i]

          _http.responseJSON err, data, res 
    
)

_app.delete('/api/agent', (req, res, next)->
  directive =  _config.previewDirectory + '/' +req.body.dir
  if _fs.existsSync directive
    _fs.removeSync directive
    return res.end 'success'
  res.end 'false'
)

_app.get('/api/lock/:project_name', (req, res, next)->
  console.log req.params
  directive =  _config.previewDirectory + '/' + req.params.project_name + "/.lock"
  if _fs.existsSync directive
  # , (result)->
  #   _http.responseJSON null, result, res
    return res.end 'true'

  res.end 'false'
  
)

#供服务器询询用
_app.get('/are-you-working', (req, res, next)->
  data =
    version: require('./package.json').version
    previewDirectory: _config.previewDirectory
  _http.responseJSON null, data, res
)

#接收并处理主服务器提交过来的分发内容
_app.post('/', (req, res, next)->
  _utils.emitRealLog(
    message: '代理服务器收到分发请求'
    body: req.body
    type: 'agent'
  )
  
  queue = []

  queue.push((done)->
    _fs.exists _config.previewDirectory + "/" + req.body.project_name + "/.lock", (result)->
      done null, result
  )

  queue.push((locked, done)->
    done null, false if !locked
    _fs.readFile _config.previewDirectory + "/" + req.body.project_name + "/.lock", 'utf-8', (err, result)->
      locked = JSON.parse(result).owner isnt req.body.owner
      done null, locked
  )

  _async.waterfall(queue,(err, locked)->
    
    return _http.responseJSON err, {"err":"该项目已被加锁，无法在该服务器发布预览"}, res if locked

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

)

_app.get('/', (req, res, next)->
  res.sendfile _path.join __dirname, "/static/agent.html"
)  

_app.get('*', (req, res, next)->
  res.sendfile _path.join __dirname, "/static/#{req.params[0]}"
)
_app.listen _app.get('port')
console.log "Port: #{_app.get 'port'}, Now: #{new Date()}"

