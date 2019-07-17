#!/bin/bash
export LOG_TAG=true
export FABRIC_SERVERS=$FABRIC_SERVERS_MULTI_ORG
export FABRIC_VERSION=hlfv12
#export FABRIC_EV=$FABRIC_SERVERS/first-network
export FABRIC_CERT_FD=cert
export SRC_BNA_FD="bmk_bc_dtp/dist/bmk_bc_dtp.bna"
export CUR_COMPLIE_BNA_FD=chaincode
_current_path=$(cd `dirname $0` && pwd)
echo $_current_path
export FABRIC_EV=$(dirname "$PWD")
_exp_usercards=$_current_path/userCards
_exp_adminCA=$_current_path/$FABRIC_CERT_FD/adminCA
_exp_orgCA=$_current_path/$FABRIC_CERT_FD/orgCA
_ccVersionNum="0.0.1"
_ccName="bmk_bc_dtp"

echo $FABRIC_EV
echo $_current_path
echo $FABRIC_VERSION
callbackMsg(){
    _status=$1
    _errMsg=$2
    echo '{"status":"'$_status'","message":"'$_errMsg'"}'
}

#提示帮助
usage() {
    echo ""
    echo "Usage: ./deploy_fabric_servers.sh [--help] [-n]"
    echo "How to deploy the blockchain network server"
    echo "Options:"
    echo -e "\t --help | -h help info"
    echo -e "\t --delete | -d would remove all images and restart "
    echo -e "\t --version | -v the chaincode version number would be installed. eg: -v 0.0.1 "
    echo ""
    exit 1
}
#定义输出
#禁止所有日志输出 > /dev/null 2>&1
#只保留错误日志 2 > ERR.LOG
#注意：0 是标准输入（STDIN），1 是标准输出（STDOUT），2 是标准错误输出（STDERR）。
outputLog(){
    if [ "$LOG_TAG" == true ]; then
        echo "BC_SERVERS==> "$1
    fi
}

#解析函数
parseArguments() {
    outputLog "to parse params number : $#"
    count=1
    while [[ $# -gt 0 ]]; do
        outputLog "Argument $count = $1"
        outputLog ${!count}
        curNumValue=${!count}
        if [ $1 == "--help" ] || [ $1 == "-h" ]; then
            HELPINFO=true
        fi
        if [ "$curNumValue"n == "--delete"n ] || [ "$curNumValue"n == "-d"n ]; then
            DELETE=true
        fi
        if [ "$curNumValue"n == "--version"n ] || [ "$curNumValue"n == "-v"n ]; then
            _versionNum=$((count+1))
            _ccVersionNum=${!_versionNum}
        fi

        count=$((count + 1))
        shift
    done
}




function removeContainer(){
    P1=$(docker ps -q)
    if [ "${P1}" != "" ]; then
        echo "Killing all running containers"  &2> /dev/null
        docker kill ${P1}
    fi
    
    P2=$(docker ps -aq)
    if [ "${P2}" != "" ]; then
        echo "Removing all containers"  &2> /dev/null
        docker rm ${P2} -f
    fi
}

function removeImages(){
    P=$(docker images -aq)
    if [ "${P}" != "" ]; then
        echo "Removing images"  &2> /dev/null
        docker rmi ${P} -f
    fi
}

checkParams(){
    if [ "${HELPINFO}" == true ]; then
        usage
    fi
}

stopFabric(){
    
    ./byfn.sh -m down
    removeContainer
    if [ "${DELETE}" == true ]; then
        removeImages
    fi
    rm -rf ~/.composer/
    rm -rf $_exp_usercards
    
}
cleanComposerCard(){
    rm -rf ~/.composer/
    rm -rf $_exp_usercards
}
startFabric(){
    ./byfn.sh -m generate
    
    ./byfn.sh -m up -s couchdb -a

}

copyCA(){
    mkdir $_exp_usercards

    #copy admin CA
    rm -rf $_exp_adminCA
    mkdir -p $_exp_adminCA/org1/users
    mkdir -p $_exp_adminCA/org2/users

    export org1AdminCA=$_exp_adminCA/org1/users
    export org2AdminCA=$_exp_adminCA/org2/users

    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem  $org1AdminCA
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/Admin@org2.example.com-cert.pem $org2AdminCA
    
    
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/*_sk $org1AdminCA
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/*_sk $org2AdminCA
    
    tree $_exp_adminCA
    
    outputLog "copy the admin CA done..."

    #copy orgnization CA
    rm -rf $_exp_orgCA
    mkdir -p $_exp_orgCA/orderer/cert
    mkdir -p $_exp_orgCA/org1/ca/cert
    mkdir -p $_exp_orgCA/org1/peer0/cert
    mkdir -p $_exp_orgCA/org1/peer1/cert
    mkdir -p $_exp_orgCA/org2/ca/cert
    mkdir -p $_exp_orgCA/org2/peer0/cert
    mkdir -p $_exp_orgCA/org2/peer1/cert

    export orderer_cert_path=$_exp_orgCA/orderer/cert/tlsca.example.com-cert.pem
    export org1_ca_cert_path=$_exp_orgCA/org1/ca/cert/ca.org1.example.com-cert.pem
    export org1_peer0_cert_path=$_exp_orgCA/org1/peer0/cert/tlsca.org1.example.com-cert.pem
    export org1_peer1_cert_path=$_exp_orgCA/org1/peer1/cert/tlsca.org1.example.com-cert.pem
     export org2_ca_cert_path=$_exp_orgCA/org2/ca/cert/ca.org2.example.com-cert.pem
    export org2_peer0_cert_path=$_exp_orgCA/org2/peer0/cert/tlsca.org2.example.com-cert.pem
    export org2_peer1_cert_path=$_exp_orgCA/org2/peer1/cert/tlsca.org2.example.com-cert.pem

    cp -r $FABRIC_EV/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem $orderer_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem $org1_ca_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem $org1_peer0_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem $org1_peer1_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem $org2_ca_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/tlscacerts/tlsca.org2.example.com-cert.pem $org2_peer0_cert_path
    cp -r $FABRIC_EV/crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/tlscacerts/tlsca.org2.example.com-cert.pem $org2_peer1_cert_path

    tree $_exp_orgCA

    #get the pem content
    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $orderer_cert_path > temp_ca.txt
    export orderer_cert=$(cat temp_ca.txt)

    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org1_ca_cert_path > temp_ca.txt
    export org1_ca_cert=$(cat temp_ca.txt)
    
    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org1_peer0_cert_path > temp_ca.txt
    export org1_peer0_cert=$(cat temp_ca.txt)

     awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org1_peer1_cert_path > temp_ca.txt
    export org1_peer1_cert=$(cat temp_ca.txt)

    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org2_ca_cert_path > temp_ca.txt
    export org2_ca_cert=$(cat temp_ca.txt)
    
    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org2_peer0_cert_path > temp_ca.txt
    export org2_peer0_cert=$(cat temp_ca.txt)

    awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $org2_peer1_cert_path > temp_ca.txt
    export org2_peer1_cert=$(cat temp_ca.txt)

    rm -rf temp_ca.txt

    #替换文件中的内容证书路径
    generateOrgConnCert 1
    generateOrgConnCert 2
}


#传入文件后缀参数，指定文件1，2 修改
generateOrgConnCert(){
#    sed -i s/'ORDERER_CERT_PATH'/"$orderer_cert"/g `grep 'ORDERER_CERT_PATH' -rl $_current_path/byfn-network-org$1.json `
#    sed -i s/'ORG1_PEER0_CERT_PATH'/"$org1_peer0_cert"/g `grep 'ORG1_PEER0_CERT_PATH' -rl $_current_path/byfn-network-org$1.json `
#    sed -i s/'ORG1_PEER1_CERT_PATH'/"$org1_peer1_cert"/g `grep 'ORG1_PEER1_CERT_PATH' -rl $_current_path/byfn-network-org$1.json `
#    sed -i s/'ORG2_PEER0_CERT_PATH'/"$org2_peer0_cert"/g `grep 'ORG2_PEER0_CERT_PATH' -rl $_current_path/byfn-network-org$1.json `
#    sed -i s/'ORG2_PEER1_CERT_PATH'/"$org2_peer1_cert"/g `grep 'ORG2_PEER1_CERT_PATH' -rl $_current_path/byfn-network-org$1.json `

    outputLog "generate  byfn-network-org$1"

cat << EOF > ${_current_path}/byfn-network-org$1.json
{
    "name": "byfn-network",
    "x-type": "hlfv1",
    "version": "1.0.0",
    "client": {
        "organization": "Org$1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "500",
                    "eventHub": "500",
                    "eventReg": "500"
                },
                "orderer": "500"
            }
        }
    },
    "channels": {
        "mychannel": {
            "orderers": [
                "orderer.example.com"
            ],
            "peers": {
                "peer0.org1.example.com": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "ledgerQuery": true,
                    "eventSource": true
                },
                "peer1.org1.example.com": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
		     "ledgerQuery": true,
                    "eventSource": true
                },
                "peer0.org2.example.com": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
		     "ledgerQuery": true,
                    "eventSource": true
                },
                "peer1.org2.example.com": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
		     "ledgerQuery": true,
                    "eventSource": true
                }
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": [
                "peer0.org1.example.com",
                "peer1.org1.example.com"
            ],
            "certificateAuthorities": [
                "ca.org1.example.com"
            ]
        },
        "Org2": {
            "mspid": "Org2MSP",
            "peers": [
                "peer0.org2.example.com",
                "peer1.org2.example.com"
            ],
            "certificateAuthorities": [
                "ca.org2.example.com"
            ]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpcs://orderer.example.com:7050",
            "grpcOptions": {
                "ssl-target-name-override": "orderer.example.com"
            },
            "tlsCACerts": {
                "pem": "${orderer_cert}"
            }
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpcs://peer0.org1.example.com:7051",
            "grpcOptions": {
                "ssl-target-name-override": "peer0.org1.example.com"
            },
            "tlsCACerts": {
                "pem": "${org1_peer0_cert}"
            }
        },
        "peer1.org1.example.com": {
            "url": "grpcs://peer1.org1.example.com:8051",
            "grpcOptions": {
                "ssl-target-name-override": "peer1.org1.example.com"
            },
            "tlsCACerts": {
                "pem": "${org1_peer1_cert}"
            }
        },
        "peer0.org2.example.com": {
            "url": "grpcs://peer0.org2.example.com:9051",
            "grpcOptions": {
                "ssl-target-name-override": "peer0.org2.example.com"
            },
            "tlsCACerts": {
                "pem": "${org2_peer0_cert}"
            }
        },
        "peer1.org2.example.com": {
            "url": "grpcs://peer1.org2.example.com:10051",
            "grpcOptions": {
                "ssl-target-name-override": "peer1.org2.example.com"
            },
            "tlsCACerts": {
                "pem": "${org2_peer1_cert}"
            }
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "https://ca.org1.example.com:7054",
            "caName": "ca-org1",
            "httpOptions": {
                "verify": false
            },
            "tlsCACerts": {
                "pem": "${org1_ca_cert}"
            }
        },
        "ca.org2.example.com": {
            "url": "https://ca.org2.example.com:8054",
            "caName": "ca-org2",
            "httpOptions": {
                "verify": false
            },
            "tlsCACerts": {
                "pem": "${org2_ca_cert}"
            }
        }
    }
}
EOF

}


#Attention: the cert path where in set at xxx.json
createPeerAdminCard(){
    #create the channel admin card
    composer card create -p $_current_path/byfn-network-org1.json -u PeerAdmin -c $org1AdminCA/Admin@org1.example.com-cert.pem -k $org1AdminCA/*_sk -r PeerAdmin -r ChannelAdmin -f $_exp_usercards/PeerAdmin@byfn-network-org1.card
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to create org1 admin user."
        exit
    fi
    composer card create -p $_current_path/byfn-network-org2.json -u PeerAdmin -c $org2AdminCA/Admin@org2.example.com-cert.pem -k $org2AdminCA/*_sk -r PeerAdmin -r ChannelAdmin -f $_exp_usercards/PeerAdmin@byfn-network-org2.card
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to create org2 admin user."
        exit
    fi
    outputLog "create the admin business card done"
    #import the channel admin card
    composer card import -f $_exp_usercards/PeerAdmin@byfn-network-org1.card --card PeerAdmin@byfn-network-org1
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to import org1 peer admin card."
        exit
    fi
    composer card import -f $_exp_usercards/PeerAdmin@byfn-network-org2.card --card PeerAdmin@byfn-network-org2
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to import org2 peer admin card."
        exit
    fi
    composer card list
    outputLog "import the admin card done..."
    
}

getCCFile(){
    cd $_current_path
    rm -rf $CUR_COMPLIE_BNA_FD
    mkdir $CUR_COMPLIE_BNA_FD
    chmod 777 $CUR_COMPLIE_BNA_FD
    cp -r "${SRC_BNA_FD}" "$CUR_COMPLIE_BNA_FD/$_ccName.bna"
    _theLocBNA="$_current_path/$CUR_COMPLIE_BNA_FD/$_ccName.bna"
    if test -e $_theLocBNA
    then
        callbackMsg "$INFO" "$_ccName文件存在!"
    else
        callbackMsg "$INFO" "$_ccName文件不存在!"
        return
    fi
    cd $FABRIC_EV
}

installChaincode() {
    getCCFile
    
    outputLog "$_theLocBNA"
    #install chaincode
    composer network install --card PeerAdmin@byfn-network-org1 --archiveFile "$_theLocBNA"
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to install chaincode by org1 admin."
        exit
    fi
    composer network install --card PeerAdmin@byfn-network-org2 --archiveFile "$_theLocBNA"
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to install chaincode by org2 admin."
        exit
    fi
    outputLog "install chaincode  done..."
    
    #assign org1 chaincode the network admin user
    composer identity request -c PeerAdmin@byfn-network-org1 -u admin -s adminpw -d $_exp_usercards/org1NwAdmin
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to identity request by org1 admin."
        exit
    fi
    #assign org2 chaincode the network admin user
    composer identity request -c PeerAdmin@byfn-network-org2 -u admin -s adminpw -d $_exp_usercards/org2NwAdmin  
      
}

startCC(){
    #start the network
    outputLog "will start version number $_ccVersionNum"
    composer network start -c PeerAdmin@byfn-network-org1 -n bmk_bc_dtp -V $_ccVersionNum -o endorsementPolicyFile=$_current_path/endorsement-policy.json -A $_exp_usercards/org1NwAdmin -C $_exp_usercards/org1NwAdmin/admin-pub.pem -A $_exp_usercards/org2NwAdmin -C $_exp_usercards/org2NwAdmin/admin-pub.pem
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to install start chaincode network"
        exit
    fi
}

createOrgAdminCard(){
    #create the org1 admin user card
    composer card create -n bmk_bc_dtp -p $_current_path/byfn-network-org1.json -u org1NwAdmin -c $_exp_usercards/org1NwAdmin/admin-pub.pem -k $_exp_usercards/org1NwAdmin/admin-priv.pem -f $_exp_usercards/org1NwAdmin@bmk_bc_dtp.card
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to create org1 admin card"
        exit
    fi
    #import the org1 admin card
    composer card import -f $_exp_usercards/org1NwAdmin@bmk_bc_dtp.card 
    if [ $? -ne 0 ]; then
        callbackMsg "$FAILED" "failed to import org1 admin card"
        exit
    fi
    
    outputLog "create admin card successfully."
    
}

mainCmd(){
    parseArguments $*
    checkParams
    pwd
#    cd $FABRIC_EV
#    stopFabric
    
#    startFabric
    if [ "${DELETE}" == true ]; then
      cleanComposerCard
    fi

    copyCA
    
    createPeerAdminCard
    
    installChaincode
    
    startCC
    
    createOrgAdminCard
    
    cd $_current_path
    pwd
    
}

mainCmd $*





