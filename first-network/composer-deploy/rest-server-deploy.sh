#!/bin/bash
export LOG_TAG=true
export DEF_LOCAL_DATA_HOME="$HOME/.composer" #本地区块链数据
export DEF_SCRIPT_CONFIG_FOLDER="config" #脚本执行配置文件存放目录
export DEF_DOCKER_IMAGE_RESTOAUTH="bmk_rest/composer-rest-server" #定义RESTFUL API SERVER OAUTH 的镜像名称
export DEF_DOCKER_CONTAINER_RESTOAUTH="bmk_rest" #定义RESTFUL API SERVER OAUTH 的容器名称
export DEF_DOCKER_ENV_FILE=$DEF_SCRIPT_CONFIG_FOLDER"/env-rest-server"
export DEF_FABRIC_NW_NAME="my-net" #fabric 启动时配置的网络名称，必须一致
_port=3000   #default port
_envFilePath=$DEF_DOCKER_ENV_FILE  #default env
_dcNetworkName=$DEF_FABRIC_NW_NAME
#提示帮助
Usage() {
	echo ""
	echo "Usage: ./step5_start_restservers.sh [--help] [-n]"
	echo "How to generate restful api server"
    echo -e "[options:]"
    echo -e "\t --file | -f the file path of setting environment variable "
    echo -e "\t --port | -p set the network port "
    echo -e "\t --network | -n set the network name (you can find it by command docker network list) "
    echo -e "\t --help | -h help info"
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
#  outputLog "to parse params number : $#" 
	count=1
		while [[ $# -gt 0 ]]; do
#				outputLog "Argument $count = $1"
#				outputLog ${!count}
				curNumValue=${!count}
				if [ $1 == "--help" ] || [ $1 == "-h" ]; then
					HELPINFO=true
				fi
 					
				if [ "$curNumValue"n == "--port"n ] || [ "$curNumValue"n == "-p"n ]; then
					_portNum=$((count+1))
					_port=${!_portNum}
				fi

				if [ "$curNumValue"n == "--file"n ] || [ "$curNumValue"n == "-f"n ]; then
					_evnNum=$((count+1))
					_envFilePath=${!_evnNum}
				fi
                                if [ "$curNumValue"n == "--network"n ] || [ "$curNumValue"n == "-n"n ]; then
                                        _networkNum=$((count+1))
                                        _dcNetworkName=${!_networkNum}
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

    if [ "$_envFilePath"x == 'x' ];then
	   outputLog "Using the default env-rest-server"
    fi

    if [ "$_port"x == 'x' ];then
		outputLog "Using the default port 3000"
    fi
}

#配置restful api 访问权限
setRestfulapiOAuth(){
    outputLog " build docker oauth image..."
    docker build -t $DEF_DOCKER_IMAGE_RESTOAUTH ./$DEF_SCRIPT_CONFIG_FOLDER
    if [ $? -ne 0 ]; then
		callbackMsg "Failed to build dtp_restapi_oauth conainter."
	fi

    #设置COMPOSER REST API 环境变量
    outputLog "source env $_envFilePath"
    source $_envFilePath
    outputLog " build docker oauth image DONE"
}
#安装和启动mongodb
startMongoDB(){
    docker run -d --name mongo --network $_dcNetworkName -p 27017:27017 mongo  
    if [ $? -ne 0 ]; then
		callbackMsg "Failed to modity the user connectio.json ."
	fi
}

runRestfulApiServer(){
    #启动docker 使用xxx镜像以后台模式启动一个名称为xxx的容器，主机端口对应容器端口，主机的目录 /data 映射到容器的 /data, 
    #并设置了一些环境变量
    outputLog "----------- docker run image container BEGIN..."
    outputLog "$DEF_DOCKER_CONTAINER_RESTOAUTH"
    outputLog "$DEF_DOCKER_IMAGE_RESTOAUTH"
    outputLog "$DEF_LOCAL_DATA_HOME"
    outputLog "${COMPOSER_CARD}"
    outputLog "${COMPOSER_DATASOURCES}"

    chmod -R 777 $DEF_LOCAL_DATA_HOME
    
    startMongoDB

    docker run \
    -d \
    --rm -it --network="$_dcNetworkName" \
    --link ca.example.com:ca.example.com \
    --link orderer.example.com:orderer.example.com \
    --link peer0.org1.example.com:peer0.org1.example.com \
    --link peer1.org1.example.com:peer1.org1.example.com \
    -e COMPOSER_CARD=${COMPOSER_CARD} \
    -e COMPOSER_NAMESPACES=${COMPOSER_NAMESPACES} \
    -e COMPOSER_AUTHENTICATION=${COMPOSER_AUTHENTICATION} \
    -e COMPOSER_MULTIUSER=${COMPOSER_MULTIUSER} \
    -e COMPOSER_PROVIDERS="${COMPOSER_PROVIDERS}" \
    -e COMPOSER_DATASOURCES="${COMPOSER_DATASOURCES}" \
    -v ${DEF_LOCAL_DATA_HOME}:/home/composer/.composer \
    --name ${DEF_DOCKER_CONTAINER_RESTOAUTH} \
    -p $_port:$_port \
    ${DEF_DOCKER_IMAGE_RESTOAUTH}

    outputLog "==== run done ==== "
    docker logs $DEF_DOCKER_CONTAINER_RESTOAUTH
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
    setRestfulapiOAuth
    runRestfulApiServer
    outputLog "===>Exec FINISH..."
}

cmdMain $*





