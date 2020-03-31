#!/bin/sh

SQUID_VERSION=3.5.8
var=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
for (( i = 0; i < 10; i++ )); do
	#statements
done
echo "Add repositories to Aptitude"
echo "deb http://httpredir.debian.org/debian stable main" > /etc/apt/sources.list.d/squid.list
echo "deb-src http://httpredir.debian.org/debian stable main" >> /etc/apt/sources.list.d/squid.list
echo "deb http://security.debian.org/ stable/updates main" >> /etc/apt/sources.list.d/squid.list
echo "deb-src http://security.debian.org/ stable/updates main" >> /etc/apt/sources.list.d/squid.list

echo "Update packages list"
apt-get update
echo "Build dependencies"
apt-get -y install build-essential libssl-dev apache2-utils
apt-get -y build-dep squid3 squid3-common apache2-utils

echo "Download source code"n
cd /usr/src
wget http://www.squid-cache.org/Versions/v3/3.5/squid-${SQUID_VERSION}.tar.gz
tar zxvf squid-${SQUID_VERSION}.tar.gz
cd squid-${SQUID_VERSION}

echo "Build binaries"
./configure CXXFLAGS="-DMAXTCPLISTENPORTS=30000" --prefix=/usr \
	--localstatedir=/var/squid \
	--libexecdir=${prefix}/lib/squid \
	--srcdir=. \
	--datadir=${prefix}/share/squid \
	--sysconfdir=/etc/squid \
	--with-default-user=proxy \
	--with-logdir=/var/log/squid \
	--with-pidfile=/var/run/squid.pid
make -j$(nproc)

echo "Stop running service"
service squid stop

echo "Install binaries"
make install

echo "Download libraries"
cd /usr/lib
wget -O /usr/lib/squid-lib.tar.gz https://github.com/recepasan/squid/raw/master/squid-lib.tar.gz

echo "Install libraries"
tar zxvf squid-lib.tar.gz

echo "Create configuration file"
rm -rf /etc/squid/squid.conf
wget --no-check-certificate -O /etc/squid/squid.conf https://gist.githubusercontent.com/recepasan/8c429caab7b73807ed2b11956b336179/raw/09d971c398a05fb6e6afb418305bedef028ab325/squid.conf

echo "Create users database sample"
rm -rf /etc/squid/users.pwd
htpasswd -cbd /etc/squid/users.pwd proxy proxy

echo "Create service executable file"
wget --no-check-certificate -O /etc/init.d/squid https://gist.githubusercontent.com/recepasan/8c429caab7b73807ed2b11956b336179/raw/09d971c398a05fb6e6afb418305bedef028ab325/squid.sh
chmod +x /etc/init.d/squid

echo "Register service to startup entries"
update-rc.d squid defaults

echo "Prepare environment for first start"
mkdir /var/log/squid
mkdir /var/cache/squid
mkdir /var/spool/squid
chown -cR proxy /var/log/squid
chown -cR proxy /var/cache/squid
chown -cR proxy /var/spool/squid
squid -z



echo "Start service"
service squid start

echo "Cleanup temporary files"
rm -rf /etc/apt/sources.list.d/squid.list
rm -rf /usr/src/squid-${SQUID_VERSION}.tar.gz
rm -rf /usr/src/squid-${SQUID_VERSION}
rm -rf /usr/lib/squid-lib.tar.gz

echo "Proxy Adress"
echo proxy:proxy@${var}:30000:59999

exit 0
