#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/13/15 10:53 AM
#    Description:

define [

], ()->
  #去除前后的空格
  trim: (text)-> text and text.replace(/^\s+/, "" ).replace(/\s+$/, "")
  #格式化文本
  formatString: (text, args...)->
    return text if not text
    #如果第一个参数是数组，则直接使用这个数组
    args = args[0] if args.length is 1 and args[0] instanceof Array
    text.replace /\{(\d+)\}/g, (m, i) -> args[i]

  #提取text中包括规则的模板html，即包含在textarea中的
  extractTemplate: (expr, text)->
    $(text).find(expr).val()