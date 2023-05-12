#/bin/bash
#
# Script Name: mysql5.7_install_script.sh
# Author: Guo Wei
# Date: 2023-04-19
# Version: 1.0
# Description: 仅限于conetos7 通过mysql-5.7.29-1.el7.x86_64.rpm-bundle.tar安装，会自动卸载掉系统自带的mariadb相关组件
# 
function install_the_required_software() {
if ! which $software &> /dev/null
then
	yum install $software -y &> /dev/null
	echo "安装需要软件$software......"
fi
}

function remove_conflicting_software() {
if rpm -aq |grep $software >> /opt/.template.txt
then
	for line_software in $(cat /opt/.template.txt)
	do
		yum remove $line_software -y &> /dev/null
		echo "卸载冲突软件$line_software......"
	done
	rm -rf /opt/.template.txt
fi
}

function judge_is_ok() {
echo $?
}

function judge_firewalld_service_is-active() {
if systemctl is-active firewalld &> /dev/null
then
	firewall-cmd --zone=public --add-port=3306/tcp --permanent $> /dev/null
	firewall-cmd --reload &> /dev/null
	echo "防火墙开放MySQL3306端口"
else
	echo "防火墙已经关闭"
fi
}

function get_MySQL() {
mkdir /opt/mysql && echo "下载MySQL5.7中......" && wget -P /opt/mysql/ https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.29-1.el7.x86_64.rpm-bundle.tar &> /dev/null
echo "解压MySQL中......" && tar -xvf /opt/mysql/mysql-5.7.29-1.el7.x86_64.rpm-bundle.tar -C /opt/mysql/ &> /dev/null
echo "安装MySQL软件......" && rpm -ivh /opt/mysql/mysql*rpm --nodeps &> /dev/null
}

function set_mysql_root_passwd() {
if [ $# -eq 1 ]; then
    NEWPASS=$1
else
    read -s -p "修改mysql的root密码为: " NEWPASS
fi
expect -c "
    spawn mysql -uroot -p$kaka
    expect \">\" { send \"use mysql;\\r\" }
    expect \">\" { send \"alter user user() identified by '$NEWPASS';\\r\" }
    expect \">\" { send \"grant all privileges on *.* to 'root'@'%' identified by '$NEWPASS' with grant option;\\r\" }
    expect \">\" { send \"flush privileges;\\r\" }
    expect \">\" { send \"exit\\r\" }
"
sleep 1
}

software="expect wget libaio"
install_the_required_software

software=mysql
remove_conflicting_software
software=mariadb
remove_conflicting_software

get_MySQL

echo "开始初始化MySQL"
mysqld --initialize
kaka=$(grep root@localhost /var/log/mysqld.log | cut -d" " -f11)
useradd -s /sbin/nologin mysql &> /dev/null
chown -R mysql:mysql /var/lib/mysql
echo "mysql的临时密码为  $kaka  "
echo "设置MySQL开机自启"
systemctl enable --now mysqld

set_mysql_root_passwd

judge_firewalld_service_is-active

rm -rf /opt/mysql
sleep 1
echo "MySQL5.7安装完成"
