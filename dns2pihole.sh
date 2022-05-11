#!/bin/bash

# Automate the process of setting up DNS records in Pihole,
# installed by Docker into the directory '/home/docker/pihole'.
# image: pihole/pihole:latest
# volumes:
#      - './config/etc/pihole:/etc/pihole'
#      - './config/etc/dnsmasq.d:/etc/dnsmasq.d'

# The script should be run as root
[[ "$EUID" -ne 0 ]] && { echo "Please run as root (use sudo)."; exit 0; }

# Settings
BASE_DOMAIN="example.com" # ="$(dnsdomainname -f)"
DEFAULT_IP="192.168.1.50" # ="$(dnsdomainname -i)"
TIME_ID=$(date +%Y.%m.%d.%Hh.%Mm)

PIHOLE_CUSTOM_LIST="/home/docker/pihole/config/etc/pihole/custom.list"

# At least sub-domain name and the proxied application port must be provided
if [[ -z ${1+x} ]]
then
	echo "dns2pihole sub-domain [ADD=default|REMOVE] [${DEFAULT_IP}]"
	echo "The base domain is: ${BASE_DOMAIN}"
	exit
else
	SUB_DOMAIN="$1"
	VHOST="${SUB_DOMAIN}.${BASE_DOMAIN}"
fi

if [[ -z ${2+x} ]]
then
	ACTION="add"
else
	ACTION="$2"
fi

if [[ -z ${3+x} ]]
then
	IP_IN_USE="$DEFAULT_IP"
else
	IP_IN_USE="$3"
fi

# Function add/create/enable
function add() {
	if grep -Pq -- "${VHOST}" "${PIHOLE_CUSTOM_LIST}"
	then
		echo "The entry '${IP_IN_USE} ${VHOST}' exists!"
	else
		echo "${IP_IN_USE} ${VHOST}" >> "${PIHOLE_CUSTOM_LIST}" && \
		docker exec pihole pihole restartdns && \
		echo "The entry '${IP_IN_USE} ${VHOST}' is created."
	fi
}

# Function remove/delete
function remove() {
	if grep -Pq -- "${VHOST}" "${PIHOLE_CUSTOM_LIST}"
	then
		sed -i.bak "/${VHOST}/d" "${PIHOLE_CUSTOM_LIST}" && \
		docker exec pihole pihole restartdns && \
		echo "The entry '${IP_IN_USE} ${VHOST}' is removed."
	else
		echo "The entry '${IP_IN_USE} ${VHOST}' doesn't exist!"
	fi
}

# Do the Action
if [[ ${ACTION^^} == 'ADD' ]]
then
	add
elif [[ ${ACTION^^} == 'REMOVE' ]]
then
	remove
else
        echo "dns2pihole sub-domain [ADD=default|REMOVE] [${DEFAULT_IP}]"
        echo "The base domain is: ${BASE_DOMAIN}"
fi
