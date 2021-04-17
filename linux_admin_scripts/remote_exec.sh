#!/bin/bash

if [[ $# = 0 ]]
then
        echo "Please use '-h' for help"
        exit 1
fi

which sshpass > /dev/null 2>&1
if [[ $? = 1 ]]
then
	echo "Please install sshpass"
	exit 1
fi

which nmap > /dev/null 2>&1
if [[ $? = 1 ]]
then
	echo "Please install nmap"
	exit 1
fi

which nslookup > /dev/null 2>&1
if [[ $? = 1 ]]
then
	echo "Please install nslookup"
	exit 1
fi

# Env
hostlist=/tmp/hostlist

# Create ip list
get_servers_ip(){
	read -p "Start ip (in ip range) like 192.168.1.1: " start_ip
	read -p "End ip (in ip range) only last octet, like 255: " end_ip
#	hostlist=(`nmap -Pn -n -p22 $start_ip'-'$end_ip --open | grep "$(echo $start_ip | awk -F. '{print $1"."$2"."$3}')" | awk '{print $5}'`)
	nmap -Pn -n -p22 $start_ip'-'$end_ip --open | grep "$(echo $start_ip | awk -F. '{print $1"."$2"."$3}')" | awk '{print $5}' > /tmp/hostlist
	echo "$(cat /tmp/hostlist | wc -l) ip was finded. See in file /tmp/hostlist"
}

# Get user and password
get_password() {
	read -p "Sudo user login: " user
	read -p "Sudo user password: " -s userpassword
	echo
}

# Exec command
exec_command() {
	get_password
	if [ ! -f /tmp/hostlist ]
	then
		echo "IP LIST NOT FOUND"
		read -p "Do you want to create ip list y/n?: " qw
		if [[ $qw = "y" ]]
		then
			get_servers_ip
		else
			exit 1
		fi
	fi
	read -p "Write command to execute on servers: " send_command
	for server in $(cat $hostlist); do
	echo " --------------------------- connecting to "$(nslookup $server | grep "name" | awk '{print $4}')" "$server" --------------------------"
		if [[ $2 = '-sudo' ]]
		then
			echo
			sshpass -p $userpassword ssh -oStrictHostKeyChecking=no $user@$server "echo $userpassword | sudo -kS su -c '$send_command'"
		else
			echo
			sshpass -p $userpassword ssh -oStrictHostKeyChecking=no $user@$server "$send_command"
		fi
	echo
	echo " --------------------------closing connection to "$(nslookup $server | grep "name" | awk '{print $4}')" "$server" --------------------"
	echo
	echo
	echo
	echo
	done
}

# Change password
change_password() {
	get_password
	read -p "User login for changing password: " user2
	read -p "New user password: " -s newpasswd
	if [ ! -f /tmp/hostlist ]
	then
		echo "IP LIST NOT FOUND"
		read -p "Do you want to create ip list y/n?: " qw
		if [[ $qw = "y" ]]
		then
			get_servers_ip
		else
			exit 1
		fi
	fi
	echo
	for server in $(cat $hostlist); do
	echo " --------------------------- connecting to "$server" --------------------------"
	sshpass -p $userpassword ssh -oStrictHostKeyChecking=no $user@$server "echo $userpassword | sudo -kS sh -c 'echo $user2:$newpasswd | chpasswd'"
	echo " --------------------------closing connection to "$server" --------------------"
	echo
	echo
	echo
	echo
	done
}

# Ssh key deploy
sshkey_deploy(){
	get_servers_ip
	get_password
	for server in $(cat $hostlist); do
	echo " --------------------------- connecting to "$server" --------------------------"
	sshpass -p $userpassword ssh-copy-id -oStrictHostKeyChecking=no $user@$server
	echo " --------------------------closing connection to "$server" --------------------"
	echo
	echo
	echo
	echo
	done
}

case $@ in 
	-h) 
	echo "Use parameters:"
	echo "   '-get-servers-ip' to create linux-servers ip list"
	echo "   '-change-password' to change root password, '-scan-ip' to create ip list first"
	echo "   '-send-command' to send command on servers, add '-sudo' to run as sudo user, '-scan-ip' to create ip list first"
	echo "   '-sshkey-deploy' to deploy ssh key on servers, '-scan-ip' to create ip list first"
        exit 0
        ;;
        
        -scan-ip*)		get_servers_ip
        ;;
        
        -get-servers-ip*)	get_servers_ip
        ;;
        
        -change-password*)	change_password
        ;;
        
        -send-command*)		exec_command "$@"
        ;;
        
        -sshkey-deploy*)	sshkey_deploy
        ;;

esac
