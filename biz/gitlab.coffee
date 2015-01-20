#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/19/15 5:40 PM
#    Description: 与gitlab相关的部分

_async = require 'async'
_path = require 'path'
_cheerio = require 'cheerio'
_transport = require './transport'

#提取单个标签信息
extractTag = ($item)->
  title = item.find('h4>a').text();
  message = item.find('.commit-row-message').text();
  url = item.find('.commit-row-message').attr('href');
  pattern = /^.+\/commit\/(.+)$/
  hash = url.replace(pattern, '$1')

  return {
    title: title
    message: message
    hash: hash
    url: url
  }

#分析返回的HTML
analyseHTML = (content, cb)->
  tags = []

  $ = _cheerio.load content
  #只取前10个标签
  $('ul.bordered-list>li:lt(10)').each (item)->
    #tags.push extractTag(item)

#http://git.hunantv.com/honey-lab/imgotv/tags
fetchTags = (repos, cb)->
  options =
    url: repos
    'auth': {
      'user': 'conis.yi@gmail.com',
      'pass': '12345678',
      'sendImmediately': true
    }

  _transport.request options, (err, res, body)->
    return console.log body
    return cb err if err
    data = statusCode: res.statusCode

    if data.statusCode is 200
      tags = analyseHTML(body)
      console.log tags

#获取所有的标签
exports.getTags = (token, repos, cb)->
  fetchTags 'http://git.hunantv.com/honey-lab/imgotv/tags'