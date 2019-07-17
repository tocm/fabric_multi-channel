#!/bin/bash
export LOG_TAG=true
export DEF_GENERATE_CARDS_FOLDER="userCards" #导出用户卡存放目录
export DEF_LOCAL_DATA_HOME="$HOME/.composer" #本地区块链数据
export BC_LOCAL_USERCARDS="$DEF_LOCAL_DATA_HOME/cards" #本地区块链用户卡数据存放位置
export _org_count='1' #定义组织个数, eg: 两个Org: '1, 2'

#提示帮助
Usage() {
	echo ""
	echo "Usage: ./genesisUser.sh [--help] [-n]"
	echo "Generate a platform genesis user and publish the maximum coins "
	echo "Options: default THE INFO is [ U001, bmk2019, bmk@bmkcrypto.com ]"
	echo -e "\t --uid | -u the string uid of the User participant"
	echo -e "\t --cid | -c the string cid of the Coin Asset id"
	echo -e "\t --name | -n the sting name of the User participant"
	echo -e "\t --email | -e the string email of the User participant"
	echo -e "\t --phone | -p the string phone of the User participant"
	echo -e "\t --max | -m the max coins would be published. default is 500000000"
	echo ""
	exit 1
}
#定义输出
#禁止所有日志输出 > /dev/null 2>&1
#只保留错误日志 2 > ERR.LOG
#注意：0 是标准输入（STDIN），1 是标准输出（STDOUT），2 是标准错误输出（STDERR）。
outputLog(){
	if [ "$LOG_TAG" == true ]; then
		echo "GENERATOR==> "$1
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
				if [ "$curNumValue"n == "--uid"n ] || [ "$curNumValue"n == "-u"n ]; then
					_uidNum=$((count+1))
					_uid=${!_uidNum}
				fi

				if [ "$curNumValue"n == "--cid"n ] || [ "$curNumValue"n == "-c"n ]; then
					_cidNum=$((count+1))
					_cid=${!_cidNum}
				fi
 					
				if [ "$curNumValue"n == "--name"n ] || [ "$curNumValue"n == "-n"n ]; then
					_nameNum=$((count+1))
					_name=${!_nameNum}
				fi

				if [ "$curNumValue"n == "--email"n ] || [ "$curNumValue"n == "-e"n ]; then
					_emailNum=$((count+1))
					_email=${!_emailNum}
				fi

				if [ "$curNumValue"n == "--phone"n ] || [ "$curNumValue"n == "-p"n ]; then
					_phoneNum=$((count+1))
					_phone=${!_phoneNum}
				fi

				if [ "$curNumValue"n == "--max"n ] || [ "$curNumValue"n == "-m"n ]; then
					_maxCoinsNum=$((count+1))
					_maxCoins=${!_maxCoinsNum}
				fi
				
				count=$((count + 1))
				shift
		done
}
#定义用户卡名称规则
defineUserCardName(){
	_userCardName=$_uid"_"$_name
	_userCard="$_userCardName.card"
	_expCardPath=$DEF_GENERATE_CARDS_FOLDER"/"$_userCardName"_exp.card" 
	outputLog "defined card name is $_userCard"
}

#函数创建临时存放用户卡目录
createUsercardsFolder(){
	if  test -d "$DEF_GENERATE_CARDS_FOLDER" 
	then
		outputLog "已存在目录"
		cd $DEF_GENERATE_CARDS_FOLDER
		if test -e "$_userCard" 
		then
			outputLog "$_userCard已存在，将删除"
			rm -rf "$_userCard"
		fi

		if test -e $_userCardName"_exp.card"  
		then
			outputLog "$_userCardName exp.card 已存在，将删除"
			rm -rf $_userCardName"_exp.card"
		fi
		cd ..
	else
		outputLog "创建新目录: $DEF_GENERATE_CARDS_FOLDER"
		mkdir $DEF_GENERATE_CARDS_FOLDER
		chmod 777 $DEF_GENERATE_CARDS_FOLDER
	fi
}

checkInputParams(){
	if [ "X${_uid}" == "X" ];then
        _uid="U001"
    #callbackMsg "input the uid is null. please use -u xxx "
	fi
	if [ "X${_name}" == "X" ];then
        _name="bmk2019"
        #callbackMsg "input the name is null. please use -n xxx "
	fi
	if [ "X${_email}" == "X" ];then
        _email="bmk@bmkcrypto.com"
        #callbackMsg "input the email is null. please use -e xxx "
	fi
	if [ "X${_phone}" == "X" ];then
        _phone="88888888"
        #callbackMsg "input the phone is null. please use -p xxx "
	fi
	if [ "X${_maxCoins}" == "X" ];then
        _maxCoins=500000000
        #callbackMsg "input the phone is null. please use -p xxx "
	fi
	if [ "X${_cid}" == "X" ];then
        _cid="co001"
    		#callbackMsg "input the coin id is null. please use -u xxx "
	fi

}
#注册创始用户
registerUserCard(){
	outputLog "composer create card BEGIN..."
	_userEntityObj='{"$class": "org.bmk.dtp.User","email": "'${_email}'","name": "'$_name'","uid": "'$_uid'","phone": "'$_phone'","status": "available","cryptoKey": "string","ownerEntity": "PLATFORM"}'
	outputLog "$_userEntityObj"
	rm -rf ./err.log
	composer participant add -c org1NwAdmin@bmk_bc_dtp -d "$_userEntityObj" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		callbackMsg "Failed to add the member."
	fi
	composer identity issue -c org1NwAdmin@bmk_bc_dtp -f $DEF_GENERATE_CARDS_FOLDER/$_userCard -u $_userCardName -a "resource:org.bmk.dtp.User#$_uid" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		callbackMsg "Failed to issue identity for the member."
	fi
	composer card import --f $DEF_GENERATE_CARDS_FOLDER/$_userCard > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		callbackMsg "Failed to import the bussness card for the member."
	fi
}

#导出创始用户
exportUserCard(){
	outputLog "export card BEGIN..."
	#_replConnfile="$BC_LOCAL_USERCARDS/$_userCardName@bmk_bc_dtp/connection.json"
	_expCardPath=$DEF_GENERATE_CARDS_FOLDER"/"$_userCardName"_exp.card" 
	outputLog $_expCardPath
	#cp -f config/pee0.org1_connection.json $_replConnfile > /dev/null 2>&1
	composer card export -f  $_expCardPath -c $_userCardName@bmk_bc_dtp > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		callbackMsg "Failed to export the bussness card ."
	fi
	rm -rf $DEF_GENERATE_CARDS_FOLDER/$_userCard > /dev/null 2>&1

}

#发布创世代币
publishGenesisCoins(){
	composer transaction submit -c org1NwAdmin@bmk_bc_dtp -d '{"$class": "org.bmk.dtp.GenesisCoin", "cuid":"'$_cid'", "amount":"'$_maxCoins'", "genesisUser": "resource:org.bmk.dtp.User#'$_uid'"}'
	if [ $? -ne 0 ]; then
		callbackMsg "Failed to publish the genesis coins."
	fi
}

#创建网络管理员
createNwAdminCards(){
    #install new chaincode version
    outputLog "createNwAdminCards step1 "
		for orgIndex in $_org_count; do
			_restAdminCardName=org$orgIndex"_restAdmin"
			outputLog $_restAdminCardName
			composer participant add -c org$orgIndex'NwAdmin@bmk_bc_dtp' -d '{"$class":"org.hyperledger.composer.system.NetworkAdmin", "participantId":"'$_restAdminCardName'"}' > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				callbackMsg "Failed to add the rest admin card."
			fi
			composer identity issue -c org$orgIndex"NwAdmin@bmk_bc_dtp" -f $DEF_GENERATE_CARDS_FOLDER/$_restAdminCardName".card" -u $_restAdminCardName -a "resource:org.hyperledger.composer.system.NetworkAdmin#$_restAdminCardName" > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				callbackMsg "Failed to issue identity for the rest admin card."
			fi
				composer card import --f $DEF_GENERATE_CARDS_FOLDER/$_restAdminCardName".card" 
			if [ $? -ne 0 ]; then
				callbackMsg "Failed to import the rest admin card for the member."
			fi

		done 
}

#返回客户端消息
callbackMsg(){
	if test -e "$_expCardPath"  
	then
		echo '{"status":"SUCCESS","message":"Created platform user successfully. User info is ['$_uid', '$_name', '$_email'], publish coins ['$_maxCoins']"}'
	else
		_errMsg=$1
		echo '{"status":"FAILD","message":"'$_errMsg'"}'
	fi
	exit 1
}

#执行解析函数
Parse_Arguments $*

#是否显示提示
if [ "${HELPINFO}" == true ]; then
    Usage
fi
checkInputParams
defineUserCardName
createUsercardsFolder
registerUserCard
createNwAdminCards
exportUserCard
publishGenesisCoins
callbackMsg
outputLog "===>Exec genesis user and coins FINISH..."

