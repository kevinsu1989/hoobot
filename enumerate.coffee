#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 4:16 PM
#    Description: 枚举

module.exports =
  TaskStatus:
    #创建成功
    Created: 1
    #任务被取消，一般是同项目的新任务进来，旧任务取消
    Canceled: 2
    #找不到服务器
    ServerNotFound: 3
    #任务处理成功
    Success: 10
    #失败
    Failure: 99