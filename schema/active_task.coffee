#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 3/16/15 9:49 AM
#    Description: 当前活动的版本

exports.schema =
  name: 'active_task'
  fields:
    #最后发布版本的hash值
    hash: ''
    #接收服务器地址
    server: ''
    #最后发布的时间
    timestamp: 'bigInteger'