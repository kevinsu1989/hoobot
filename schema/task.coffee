#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/4/15 9:46 AM
#    Description:

exports.schema =
  name: 'task'
  fields:
    #提交的hash
    hash: {type: 'string', index: true}
    #提交用户的email
    email: ''
    #commit地址，或者tag的地址
    url: 'text'
    #分支
    branch: ''
    #commit的时间
    timestamp: 'bigInteger'
    #commit的message
    message: 'text'
    #状态
    status: 'integer'
    #项目，对于到bhf的项目列表
    project_id: 'integer'
    #失败次数的计数器
    failure_counter: {type: 'integer', default: 0}
    #仓库的地址，eg. git:
    repos: 'text'
    #这条任务将要递送的目标服务器
    target: {type: 'string', index: true}
    #任务的类型
    type: {type: 'string', index: true}
    #最后的执行时间
    last_execute: 'bigInteger'
    #标签，用于release
    tag: ''