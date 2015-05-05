#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/19/15 5:40 PM
#    Description: 与gitlab相关的部分

_Gitlab = require 'gitlab'
_async = require 'async'
_path = require 'path'
_ = require 'lodash'
_http = require('bijou').http
_entity = require('../entity')
_config = require '../config'
_cache = {}

class GitLabInterface
  constructor: (token)->
    @gitlab = new _Gitlab
      url: 'http://git.hunantv.com'
      token: token

  #根据repose查找到gitlab中对应的repos_id
  findTagsOnGitlab: (project_id, sshGit, cb)->
    self = @
    #获取所有的git项目
    self.gitlab.projects.all (projects)->
      project = _.find projects, ssh_url_to_repo: sshGit
      if not project
        err = _http.notAcceptableError("没有匹配的项目，请确认Token以及您是否拥有此项目")
        return cb err

      self.gitlab.projects.repository.listTags project.id, (tags)->
        result = []

        tags = tags.sort (left, right)->
          leftDate = new Date(left.commit.committed_date).getTime()
          rightDate = new Date(right.commit.committed_date).getTime()
          if leftDate > rightDate  then -1
          else if leftDate < rightDate then 1
          else 0

        _.map tags.splice(0, 9), (tag)->
          tag.project_id = project_id
          tag.ssh_git = sshGit
          result.push tag

#        _.map tags.splice(0, 9).reverse(), (tag)->
#          result.push(
#            name: tag.name,
#            hash: tag.commit.id,
#            message: tag.commit.message
#          )

        cb null, result

#获取一个项目的所有标签
exports.refreshTag = (project_id, cb)->
  queue = []
  token = _config.gitlabToken
  sshGit = null
  tags = []

  #匹配项目信息
  queue.push(
    (done)->
      _entity.project.findById project_id, (err, result)->
        err = _http.notFoundError() if not err and not result
        return done err if err
        #如果没有设置token，则采用默认的token
        token = result.token || _config.gitlabToken
        sshGit = result.repos_git
        done err
  )

  #获取所有的标签列表
  queue.push(
    (done)->
      gli = new GitLabInterface(token)
      gli.findTagsOnGitlab project_id, sshGit, (err, result)->
        tags = result
        done err
  )

  _async.waterfall queue, (err)->
    #将错误和标签都保存到缓存中
    _cache[project_id] =
      items: tags
      success: !err
      error: err

    cb err, tags

#获取标签列表
exports.getTags = (project_id)->
  return _cache if not project_id
  _cache[project_id] || {}

#初始化，获取所有项目的标签
exports.init = (cb)->
  _entity.project.find {}, (err, projects)->
    return cb?() if err or not projects

    index = 0
    _async.whilst(
      -> index < projects.length
      (
        (done)->
          project = projects[index++]
          #忽略错误
          exports.refreshTag project.id, (err, tags)-> done null
      ), (err)-> cb?()
    )
