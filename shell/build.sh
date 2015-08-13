#!/bin/sh
# 调用方式 build.sh 远程git仓库地址 本地仓库目录 构建目录

#远程git仓库地址
REPOSITORY=$1
#本地仓库目录
LOCALDIR=$2
#构建目录
BUILDDIR=$3
#submodule的文件标识
SUBMODULE="$LOCALDIR/.gitmodules"
#将要部署的hash
HASH=$4
#将要执行的命令
#COMMAND=$5


#从远程获取代码
if [ -d "$LOCALDIR" ] ; then
    #如果已经存在，则fetch
    echo "使用git fetch拉取代码"
    cd "$LOCALDIR" && git fetch origin
else
    #不存在，clone代码
    echo "clone项目到本地"
    git clone "$REPOSITORY" "$LOCALDIR" && cd $LOCALDIR
fi

echo "切换到指定hash"
git checkout "$HASH"

#如果有submodule，则更新之
echo "$SUBMODULE"
if [ -f "$SUBMODULE" ] ; then
    echo "设置submodule"
    git submodule init && git submodule update

    #echo "更新所有的submodule"
    #git submodule foreach git fetch origin master
fi

#统一在调用的时候提供build命令
#eval $COMMAND

#if [ -z "$COMMAND" ] ; then
#    echo "执行silky命令"
#    silky build -o "$BUILDDIR" -e production
#else
#    echo "执行自定义命令"
#    eval $COMMAND
#fi