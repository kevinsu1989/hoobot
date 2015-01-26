#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/12/15 4:26 PM
#    Description: 监控代理的状况信息

_async = require 'async'
_entity = require '../entity'
_transport = require './transport'
_config = require '../config'
_utils = require '../utils'

_status = {}

#检测Silky插件和状态
checkSilkyStatus = ()->
  _utils.execCommand "silky --version", (code, message, error)->
    _status.silkyVersion = _utils.ansi2html message

  _utils.execCommand "silky list", (code, message, error)->
    _status.silkyPlugin = _utils.ansi2html message

exports.init = (cb)->
  checkSilkyStatus()
  _entity.delivery_server.find {}, (err, result)->
    _status.agents = result
    exports.update()
    cb? err

exports.get = ()-> _status

#更新所有服务器的状态
exports.update = ()->
  _status.agents = _status.agents || []
  index = 0
  _async.whilst(
    -> index < _status.agents.length
    (
      (done)->
        agent = _status.agents[index++]
        _transport.areYouWorking agent.server, (err, result)->
          agent.online = not err and result.statusCode is 200
          agent.info = result
          agent.timestamp = new Date().valueOf()
          done null
    ), ((err)->
      _utils.emitEvent 'status', _status.agents
      setTimeout (-> exports.update()), (_config.updateAgentStatusInterval || 5) * 1000 * 60
    )
  )