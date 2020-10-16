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
            return 0
            ;;

        [nN][oO]|[nN])
            return 1
            ;;

        *)
            echo "invalid input..."
            exit 1
            ;;
    esac
}

###############################################################################
# main func
###############################################################################

ShowInfo "This script helps preparing building and runtime env for GameJoyo processes."
ShowInfo "Note that it will NOT install mysqld service or redis cluster."
ShowInfo "Installation Starts ..."
MsgInput

yum install -y gcc gcc-c++ lrzsz autoconf automake libtool readline-devel git gdb cmake net-tools bzip2 wget zip unzip
yum install -y mysql mysql-devel libcurl libcurl-devel libevent libevent-devel openssl openssl-devel openssl-libs

ReportError "failed to install basic dependencies"

mkdir -p .tmp/
cd .tmp/
HOME_PATH=`pwd`


###############################################################################
# install protobuf
###############################################################################

ShowInfo "Installing protobuf 3.5.1 ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Packages/protobuf-all-3.5.1.tar.gz .
    tar -xvf protobuf-all-3.5.1.tar.gz
    cd protobuf-3.5.1/
    ./configure
    #check and report error
    make -j4
    #check and report error
    make install
    ldconfig

    echo -e "\n\tchecking protobuf version:"
    protoc --version
    #check and report error
    ReportError "failed!"

    cd ${HOME_PATH}/
fi

###############################################################################
# install go
###############################################################################

ShowInfo "Installing go 1.12.5 ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Packages/go1.12.5.linux-amd64.tar.gz .
    cp ../../Packages/golang1.12.5-and-protoc-gen-go.tar.gz .
    tar -C /usr/local -xzf go1.12.5.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc && . ~/.bashrc

    #go get github.com/golang/protobuf/protoc-gen-go
    tar zxf golang1.12.5-and-protoc-gen-go.tar.gz
    export GOPATH=$(pwd)/protoc-gen-go/
    go build -o /usr/local/go/bin/protoc-gen-go github.com/golang/protobuf/protoc-gen-go

    cd ${HOME_PATH}/
fi

###############################################################################
# install jemalloc
###############################################################################

ShowInfo "Installing jemalloc ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Packages/jemalloc-5.0.1.tar.bz2 .
    tar -xjvf jemalloc-5.0.1.tar.bz2 
    cd jemalloc-5.0.1/
    ./configure -prefix=/usr/local/jemalloc --libdir=/usr/local/lib 
    make && make install 
    echo /usr/local/lib >> /etc/ld.so.conf 
    ldconfig

    mkdir -p /usr/local/include/jemalloc
    cp include/jemalloc/jemalloc.h /usr/local/include/jemalloc/

    cd ${HOME_PATH}/
fi

###############################################################################
# install v8lib
###############################################################################

ShowInfo "Installing v8lib ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Packages/v8-5.9.1.tar.gz .
    tar -xvzf v8-5.9.1.tar.gz
    cd v8-5.9.1
    chmod +x lib/*
    cp -r include/* /usr/local/include/
    cp -r lib/* /usr/local/lib/
    cd ${HOME_PATH}/
fi

###############################################################################
# install libunwind
###############################################################################

ShowInfo "Installing libunwind ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Packages/libunwind-1.1.tar.gz .
    tar -xvzf libunwind-1.1.tar.gz
    cd libunwind-1.1
    CFLAGS=-fPIC ./configure
    make CFLAGS=-fPIC 
    make CFLAGS=-fPIC install
    cd ${HOME_PATH}/
fi

###############################################################################
# install gperftools
###############################################################################

ShowInfo "Installing gperftools ..."
MsgInput

if [ $? -eq 0 ];then
    yum install -y gperftools gperftools-devel
fi

###############################################################################
# install 腾讯交叉营销 libs ...
###############################################################################

ShowInfo "Installing 腾讯交叉营销 libs ..."
MsgInput

if [ $? -eq 0 ];then
    cp ../../Libs/libcrossmarketing_helper.a /usr/lib/libcrossmarketing_helper.a
    cp ../../Libs/libsodium.so /usr/lib/libsodium.so
    ln -s /usr/lib/libsodium.so /usr/lib/libsodium.so.23
    ldconfig
fi

###############################################################################
# final cleanup
###############################################################################
cd ../
rm -rf .tmp/

ShowInfo "All Done."
