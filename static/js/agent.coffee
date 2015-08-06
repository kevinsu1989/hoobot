getList = ()->
	$.get '/api/agent', (res)->
		html = ""
		for item in res
			html += "<tr><td>#{item.name}</td><td> <div class='ui button red' onclick=document.deleteAgent('#{item.name}',#{item.locked})>删除</div>"
			html += "<i class='lock icon'>" if item.locked
			html += "</td></tr>" 	
		$('tbody').html html


document.deleteAgent = (name, locked)->
	return if !confirm '确认删除?' 
	return if locked && !confirm '此项目已被加锁，确认删除?' 

	$.ajax 
		url: '/api/agent'
		type: 'delete'
		data: dir: name
		success: (res)->
			getList()
			alert '成功'

getList()