
console.log $('tbody')
getList = ()->
	$.get '/api/agent', (res)->
		html = ""
		html += "<tr><td>#{item}</td><td> <div class='ui button red' onclick=document.deleteAgent('#{item}')>删除</div> </td></tr>" for item in res
		$('tbody').html html


document.deleteAgent = (name)->
	return if !confirm '确认删除?'
	$.ajax 
		url: '/api/agent'
		type: 'delete'
		data: dir: name
		success: (res)->
			getList()
			alert '成功'

getList()