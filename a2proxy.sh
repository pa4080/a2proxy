#!/bin/bash
export LC_ALL=C

# The script should be run as root
[[ "$EUID" -ne 0 ]] && { echo "Please run as root (use sudo)."; exit 0; }

# Settings
BASE_DOMAIN="example.com" # ="$(dnsdomainname -f)"
DEFAULT_IP="192.168.1.50" # ="$(dnsdomainname -i)"
TIME_ID=$(date +%Y.%m.%d.%Hh.%Mm)

APACHE_VH_AVAILABLE="/etc/apache2/sites-available"
APACHE_DOCROOT_BASE="/var/www"

# At least sub-domain name and the proxied application port must be provided
if [[ -z ${1+x} ]]
then
	echo "a2proxy sub-domain 8080 [127.0.0.1]"
	echo "a2proxy sub-domain remove"
	exit
else
	SUB_DOMAIN="$1"
	VHOST="${SUB_DOMAIN}.${BASE_DOMAIN}"
fi

if [[ -z ${2+x} ]]
then
	echo "a2proxy 'sub-domain' '8080' [127.0.0.1]"
	exit
else
	PORT="$2"
fi

if [[ -z ${3+x} ]]
then
	HOST="127.0.0.1"
else
	HOST="$3"
fi

# Function add/create/enable
function create() {
	cp -i "${APACHE_VH_AVAILABLE}/a2proxy.template.conf" "${APACHE_VH_AVAILABLE}/${VHOST}.conf"
	sed -i -r \
		-e "s#example\.com#${BASE_DOMAIN}#g" \
		-e "s#proxy_#${SUB_DOMAIN}_#g" \
		-e "s#proxy.#${SUB_DOMAIN}.#g" \
		-e "s#12345#${PORT}#g" \
		-e "s#127\.0\.0\.1#${HOST}#g" \
		"${APACHE_VH_AVAILABLE}/${VHOST}.conf"

	mkdir -p "${APACHE_DOCROOT_BASE}/${VHOST}"
	echo "${VHOST} >> ${HOST}:${PORT}" > "${APACHE_DOCROOT_BASE}/${VHOST}/hello.html"

	# Test the configuration and reload apache
	a2ensite "${VHOST}.conf" && \
	apache2ctl configtest && \
	systemctl reload apache2.service && \
	echo "Enabled: https://${VHOST}"

	# Additional functions
	# dns2pihole "${SUB_DOMAIN}" add
	pm2help
}

# Function remove/delete
function remove() {
	a2dissite "${VHOST}.conf" && \
	apache2ctl configtest && \
	systemctl reload apache2.service

	mkdir -p "${APACHE_VH_AVAILABLE}/backup/"
	mv -i "${APACHE_VH_AVAILABLE}/${VHOST}.conf" "${APACHE_VH_AVAILABLE}/backup/${VHOST}.${TIME_ID}.conf"

	mkdir -p "${APACHE_DOCROOT_BASE}/backup/"
	mv -i "${APACHE_DOCROOT_BASE}/${VHOST}" "${APACHE_DOCROOT_BASE}/backup/"

	echo "Removed: https://${VHOST}"

	# Additional functions:
	# dns2pihole "${SUB_DOMAIN}" remove
	pm2help
}

# Do the Action
if [[ ${2^^} == 'REMOVE' ]]
then
	remove
else
	create
fi

# Additional functions (dns2pihole is external script)
function pm2help() {
	echo ''
	echo "https://pm2.keymetrics.io/docs/usage/startup/"
	echo "https://pm2.keymetrics.io/docs/usage/process-management/"
	echo "pm2 ls, pm2 monit, pm2 plus"
	echo ''
	echo -e "cd app/"
	echo -e "pm2 start './server.js' --name '${SUB_DOMAIN}'"
	echo -e "pm2 stop '${SUB_DOMAIN}'"
	echo -e "pm2 delete '${SUB_DOMAIN}'"
	echo -e "pm2 save \n"
}
