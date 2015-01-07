#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:33 PM
#    Description:

_fs = require 'fs'
_utils = require '../utils'
_path = require 'path'

(->
  _fs.readdirSync(__dirname).forEach (filename)->
    return if not /coffee$/.test filename or /^index\./.test filename
    key = _utils.removeExt(filename)
    module.exports[key] = require _path.join(__dirname, filename)
)()
