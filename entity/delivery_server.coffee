#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:22 PM
#    Description:

_BaseEntity = require('bijou').BaseEntity
_async = require 'async'
_ = require 'lodash'

class DeliveryServer extends _BaseEntity
  constructor: ()->
    super require('../schema/delivery_server').schema

module.exports = new DeliveryServer