#!/bin/bash
export LOG_TAG=true
export FABRIC_SERVERS=$FABRIC_SERVERS_MULTI_ORG
export FABRIC_EV=$FABRIC_SERVERS/first-network
export DEF_CONTAINER_NAME=dtp_rest_org1
export DEF_DOCKER_IMAGE_RESTOAUTH="$DEF_CONTAINER_NAME/composer-rest-server" #定义RESTFUL API SERVER OAUTH 的镜像名称
export DEF_DOCKER_CONTAINER_RESTOAUTH="$DEF_CONTAINER_NAME" #定义RESTFUL API SERVER OAUTH 的容器名称

_current_path=$(cd 'dirname $0'; pwd)
_config_fd=$_current_path #脚本执行配置文件存放目录
_authClientId="971d49bdfb34eb082195" #授权ID
_authClientSecret="1085f9265cef3b02e226c3b9b8a0ae4283168d23" #授权密
_port="3000"
_adminCardName="org1NwAdmin@bmk_bc_dtp"

#提示帮助
Usage() {
    echo ""
    echo "Usage: ./restful-servers-org1.sh [--help] [-n]"
    echo "How to generate restful api server"
    echo -e "[options] :"
    echo -e "\t --help | -h help info"
    echo -e "\t --port | -p set the network port "
    echo ""
    exit 1
}
#定义输出
#禁止所有日志输出 > /dev/null 2>&1
#只保留错误日志 2 > ERR.LOG
#注意：0 是标准输入（STDIN），1 是标准输出（STDOUT），2 是标准错误输出（STDERR）。
outputLog(){
    if [ "$LOG_TAG" == true ]; then
        echo "REST-SERVER==> "$1
    fi
}

#解析函数
Parse_Arguments() {
    outputLog "to parse params number : $#"
    count=1
    while [[ $# -gt 0 ]]; do
        outputLog "Argument $count = $1"
        outputLog ${!count}
        curNumValue=${!count}
        if [ $1 == "--help" ] || [ $1 == "-h" ]; then
            HELPINFO=true
        fi
        
        if [ "$curNumValue"n == "--port"n ] || [ "$curNumValue"n == "-p"n ]; then
            _portNum=$((count+1))
            _port=${!_portNum}
        fi
        count=$((count + 1))
        shift
    done
}

#定义用户卡名称规则
checkParams(){
    #是否显示提示
    if [ "${HELPINFO}" == true ]; then
        Usage
    fi
}

#配置restful api 访问权限
installLibs(){
    outputLog " build docker oauth image..."
    #安装到docker容器
    #docker build -t $DEF_DOCKER_IMAGE_RESTOAUTH $_config_fd
    #if [ $? -ne 0 ]; then
    #    callbackMsg "Failed to build dtp rest-server org1 conainter."
    #fi
    #直接安装缩主机
   # npm install loopback-connector-mongodb --save
    
    npm install -g passport-github
}


runRestfulApiServer(){
    cd $FABRIC_EV

    export COMPOSER_CARD=${_adminCardName}
    export COMPOSER_NAMESPACES=never
    export COMPOSER_AUTHENTICATION=true
    export COMPOSER_MULTIUSER=true
    export COMPOSER_PORT=$_port
    export COMPOSER_PROVIDERS='{
        "github": {
            "provider": "github",
            "module": "passport-github",
            "clientID": "'$_authClientId'",
            "clientSecret": "'$_authClientSecret'",
            "authPath": "/auth/github",
            "callbackURL": "/auth/github/callback",
            "successRedirect": "/",
            "failureRedirect": "/"
        }
    }'
    
    #export COMPOSER_DATASOURCES='{
     #   "db": {
      #      "name": "db",
       #     "connector": "mongodb",
        #    "host": "mongo"
       # }
    #}'
    
    outputLog "$COMPOSER_CARD"
    
  #  composer-rest-server

    composer-rest-server -c $_adminCardName  -p $_port -n never -a true -m true
    
    cd $_current_path
}

#返回客户端消息
callbackMsg(){
    _errMsg=$1
    echo '{"status":"INFO","message":"'$_errMsg'"}'
    
    exit 1
}

cmdMain(){
    
    #执行解析函数
    Parse_Arguments $*
    checkParams
    installLibs
    
    runRestfulApiServer
    outputLog "rest-server org1 FINISH..."
}

cmdMain $*




