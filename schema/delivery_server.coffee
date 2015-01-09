#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 3:06 PM
#    Description: 可分发的服务器列表

exports.schema =
  name: 'delivery_server'
  fields:
    #接收服务器地址
    target: ''
    #简短的唯一id，用于与git message中的命令对应，例如p-108，uuid应该是108
    uuid: ''