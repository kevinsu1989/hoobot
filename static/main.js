(function(){
    var socket = null
        , $container = null
        , counter = 0

    var analyseEvent = function(data){
        html = ''
        html += data.message
        return html
    }

    //呈现服务器的日志信息
    var render = function(data){
        $current = $('<div />')
        $container.append($current)

        html = new Date() + ': '
        if(typeof(data) === 'string'){
            html += data
        }else{
            html += analyseEvent (data)
        }

        $current.html(html)
    }

    //重置容器
    var resetContainer = function(){
        $container.empty()
    }

    //初始化
    var initial = function(){
        $container = $('#container')
        socket = io.connect()
        socket.on('connect', function(){
            resetContainer()
            render({message: '成功连接到服务器'})

            socket.emit('ready')
        })

        socket.on('realtime', function(data){
            counter ++
            if(counter > 100) resetContainer()
            render(data)
        })

        socket.on('status', function(data){
            console.log(data)
        })
    }

    $(document).ready(initial)
})()