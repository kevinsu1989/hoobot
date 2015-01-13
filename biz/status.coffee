#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/12/15 4:26 PM
#    Description: 监控代理的状况信息

_async = require 'async'
_entity = require '../entity'
_transport = require './transport'
_config = require '../config'
_utils = require '../utils'

_agents = []

exports.init = (cb)->
  _entity.delivery_server.find {}, (err, result)->
    _agents = result
    exports.update()
    cb? err

exports.realtimeStatus = ()-> _agents

#更新所有服务器的状态
exports.update = ()->
  index = 0
  _async.whilst(
    -> index < _agents.length
    (
      (done)->
        agent = _agents[index++]
        _transport.areYouWorking agent.server, (err, result)->
          agent.online = not err and result.statusCode is 200
          agent.info = result
          agent.timestamp = new Date().valueOf()
          done null
    ), ((err)->
      _utils.emitEvent 'status', _agents
      setTimeout (-> exports.update()), (_config.updateAgentStatusInterval || 5) * 1000 * 60
    )
  )