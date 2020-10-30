#!/bin/bash

###############################################################################
# functions
###############################################################################

function ShowInfo() {
    echo ""
    echo -e "\033[34m $1 \033[0m"
    echo ""
}

function ReportError() {
    if [ $? -ne 0 ];then
        echo -e "\033[31m $1 \033[0m"        
        exit 1
    fi
}

function MsgInput() {
    read -r -p "Proceed ? [Y/n] " input

    case $input in
        [yY][eE][sS]|[yY])
            echo -e "\033[34m ok go! \033[0m"
            ;;

        [nN][oO]|[nN])
            exit 0
            ;;

        *)
            echo -e "\033[31m invalid input! \033[0m"
            exit 1
            ;;
    esac
}

function ReplaceStrInFile() {
    file=$1
    str_src=$2
    str_dst=$3

    echo "replacing ${str_src} to ${str_dst} in ${file} ..."
    sed -i "s/${str_src}/${str_dst}/g" ${file}
}

###############################################################################
# main func
###############################################################################

ShowInfo "This script helps install redis cluster (3-master-slots and 3-slave-slots) on current local machine."
#ShowInfo "Pls make sure you've INSTALLED ruby according to following instructions:"
#echo -e "\t\tyum install -y ruby rubygems curl"
#echo -e "\t\tcurl -L get.rvm.io | bash -s stable\t\t# run 'gpg2 --keyserver **** --recv-keys ****' as listed in screen if failed and re-run 'curl -L get.rvm.io | bash -s stable'"
#echo -e "\t\tsource /usr/local/rvm/scripts/rvm"
#echo -e "\t\trvm install 2.3.3"
#echo -e "\t\trvm use 2.3.3"
#echo -e "\t\trvm remove 2.0.0"
#echo -e "\t\tgem install redis"
ShowInfo "Installation Starts ..."
MsgInput

yum install -y gcc gcc-c++ lrzsz autoconf automake libtool readline-devel git gdb cmake net-tools bzip2 wget zip unzip
yum install -y mysql mysql-devel libcurl libcurl-devel libevent libevent-devel openssl openssl-devel openssl-libs 

ReportError "failed to install basic dependencies"

mkdir -p .tmp/
cd .tmp/
HOME_PATH=`pwd`


###############################################################################
# install ruby
###############################################################################

ShowInfo "Installing ruby 2.3.3 ..."
MsgInput

cp ../../Packages/ruby-2.3.3.tar.gz .
tar -xvf ruby-2.3.3.tar.gz
cd ruby-2.3.3/
./configure
make -j4
ReportError "build failed!"
make install
ruby -v
gem sources -a https://ruby.taobao.org/
gem install redis
ReportError "install ruby failed"
cd ../


###############################################################################
# install redis-cluster service
###############################################################################

ShowInfo "Installing redis cluster 4.0.9 ..."
MsgInput

cp ../../Packages/redis-4.0.9.tar.gz .
tar -xvf redis-4.0.9.tar.gz
cd redis-4.0.9/
#./configure
##check and report error
make -j4
ReportError "build failed!"

mkdir -p /data/redis/
#cp redis.conf /data/redis/
cp ../../../Files/redis/* /data/redis/
cp src/redis-cli /data/redis/
cp src/redis-server /data/redis/
cp src/redis-trib.rb /data/redis/

cd /data/redis/
mkdir redis001 redis002 redis003 redis004 redis005 redis006
cp redis-cli redis-server redis.conf redis001/
cp redis-cli redis-server redis.conf redis002/
cp redis-cli redis-server redis.conf redis003/
cp redis-cli redis-server redis.conf redis004/
cp redis-cli redis-server redis.conf redis005/
cp redis-cli redis-server redis.conf redis006/
rm -rf redis-server
rm -rf redis.conf

# replace ENV_LOCAL_IP in redis.conf
local_ip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | awk 'NR==1')
echo ""
read -r -p "Detected local ip: ${local_ip}, correct? [y/n]" input
case $input in
    [yY][eE][sS]|[yY])
        echo -e "\033[34m we continue! \033[0m"
        ;;

    [nN][oO]|[nN])
        read -r -p "Pls type in the local ip of this machine:" localip
        local_ip=$localip
        ;;

    *)
        echo -e "\033[31m invalid input! \033[0m"
        exit 1
        ;;
esac

ReplaceStrInFile redis001/redis.conf "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile redis002/redis.conf "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile redis003/redis.conf "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile redis004/redis.conf "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile redis005/redis.conf "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile redis006/redis.conf "ENV_LOCAL_IP" ${local_ip}

# replace ENV_LOCAL_PORT in redis.conf
ReplaceStrInFile redis001/redis.conf "ENV_LOCAL_PORT" "7001"
ReplaceStrInFile redis002/redis.conf "ENV_LOCAL_PORT" "7002"
ReplaceStrInFile redis003/redis.conf "ENV_LOCAL_PORT" "7003"
ReplaceStrInFile redis004/redis.conf "ENV_LOCAL_PORT" "7004"
ReplaceStrInFile redis005/redis.conf "ENV_LOCAL_PORT" "7005"
ReplaceStrInFile redis006/redis.conf "ENV_LOCAL_PORT" "7006"

# replace ENV_LOCAL_IP in shell scripts
ReplaceStrInFile stop_all.sh "ENV_LOCAL_IP" ${local_ip}
ReplaceStrInFile create_cluster.sh "ENV_LOCAL_IP" ${local_ip}


# start all processes
chmod 755 start_all.sh
chmod 755 stop_all.sh
chmod 755 create_cluster.sh

./start_all.sh
sleep 1
./create_cluster.sh

echo ""
echo "Done. Try command '/data/redis/redis-cli -c -h ${local_ip} -p 7001' to your redis cluster."

cd ${HOME_PATH}/

###############################################################################
# final cleanup
###############################################################################
cd ../
rm -rf .tmp/

ShowInfo "All Done."
