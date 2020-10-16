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
            echo "invalid input..."
            exit 1
            ;;
    esac
}

###############################################################################
# main func
###############################################################################

ShowInfo "This script will create databases and tables using ../Files/mysql/sql/*.sql"
ShowInfo "Installation Starts ..."

MsgInput

#mysql -e "show databases"

ShowInfo "creating user: game/game123u"

mysql -e "CREATE USER 'game'@'%' IDENTIFIED BY 'game123u'"
ReportError "failed to create user: game/game123u"

mysql -e "grant all privileges on *.* to game@'%' identified by 'game123u'"
ReportError "failed to grant all privileges"

mysql -e "delete from mysql.user where User = ''"
mysql -e "flush privileges"
ReportError "failed to flush privileges"

ShowInfo "creating databases ..."

mysql -e "create database bill_joyo_1"
ReportError "failed to create database"
mysql -e "create database bill_statistics_joyo_1"
ReportError "failed to create database"

mysql -e "create database friend_joyo_1"
ReportError "failed to create database"
mysql -e "create database game_joyo_1"
ReportError "failed to create database"
mysql -e "create database mail_joyo_1"
ReportError "failed to create database"
mysql -e "create database medal_joyo_1"
ReportError "failed to create database"

ShowInfo "importing table structures ..."

mysql friend_joyo_1 < ../Files/mysql/sql/FriendDb.sql
ReportError "faile to init tables in friend_joyo_1"

mysql game_joyo_1 < ../Files/mysql/sql/GameDB.sql
ReportError "faile to init tables in game_joyo_1"

mysql mail_joyo_1 < ../Files/mysql/sql/MailDB.sql
ReportError "faile to init tables in mail_joyo_1"

mysql medal_joyo_1 < ../Files/mysql/sql/MedalDB.sql
ReportError "faile to init tables in medal_joyo_1"

ShowInfo "Done."
