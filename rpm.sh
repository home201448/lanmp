#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

clear
echo "#############################################################"
echo "# Linux + Apache + Nginx + MySQL + PHP Auto Install Script"
echo "# Env: Redhat/CentOS"
echo "# Intro: https://wangyan.org/blog/lanmp.html"
echo "# Last modified: 2012.07.21"
echo "#"
echo "# Copyright (c) 2012, WangYan <WangYan@188.com>"
echo "# All rights reserved."
echo "# Distributed under the GNU General Public License, version 3.0."
echo "#"
echo "#############################################################"
echo ""

LANMP_PATH=`pwd`
if [ `echo $LANMP_PATH | awk -F/ '{print $NF}'` != "lanmp" ]; then
	echo "Please enter lanmp script path:"
	read -p "(Default path: /root/lanmp):" LANMP_PATH
	[ -z "$LANMP_PATH" ] && LANMP_PATH="/root/lanmp"
	echo "---------------------------"
	echo "lanmp path = $LANMP_PATH"
	echo "---------------------------"
	echo ""
fi

echo "Please enter the server IP address:"
TEMP_IP=`ifconfig |grep 'inet' | grep -Evi '(inet6|127.0.0.1)' | awk '{print $2}' | cut -d: -f2`
read -p "(e.g: $TEMP_IP):" IP_ADDRESS
if [ -z $IP_ADDRESS ]; then
	IP_ADDRESS="$TEMP_IP"
fi
echo "---------------------------"
echo "IP address = $IP_ADDRESS"
echo "---------------------------"
echo ""

echo "Please enter the webroot dir:"
read -p "(Default webroot dir: /var/www):" WEBROOT
if [ -z $WEBROOT ]; then
	WEBROOT="/var/www"
fi
echo "---------------------------"
echo "Webroot dir=$WEBROOT"
echo "---------------------------"
echo ""

echo "Please enter the MySQL root password:"
read -p "(Default password: 123456):" MYSQL_ROOT_PWD
if [ -z $MYSQL_ROOT_PWD ]; then
	MYSQL_ROOT_PWD="123456"
fi
echo "---------------------------"
echo "MySQL root password = $MYSQL_ROOT_PWD"
echo "---------------------------"
echo ""

echo "Please enter the MySQL pma password:"
read -p "(Default password: 123456):" PMAPWD
if [ -z $PMAPWD ]; then
	PMAPWD="123456"
fi
echo "---------------------------"
echo "PMA password = $PMAPWD"
echo "---------------------------"
echo ""

echo "Please choose webserver software! (1:nginx,2:apache,3:nginx+apache) (1/2/3)"
read -p "(Default: 3):" SOFTWARE
if [ -z $SOFTWARE ]; then
	SOFTWARE="3"
fi
echo "---------------------------"
echo "You choose = $SOFTWARE"
echo "---------------------------"
echo ""

echo "Please choose the version of PHP: (1:php-5.2.x,2:php-5.4.x) (1/2)"
read -p "(Default version: 2):" PHP_VER
if [ -z $PHP_VER ]; then
	PHP_VER="2"
fi
echo "---------------------------"
echo "PHP Version = $PHP_VER"
echo "---------------------------"
echo ""

echo "Do you want to install xCache ? (y/n)"
read -p "(Default: y):" INSTALL_XC
if [ -z $INSTALL_XC ]; then
	INSTALL_XC="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_XC"
echo "---------------------------"
echo ""

echo "Do you want to install ioncube ? (y/n)"
read -p "(Default: y):" INSTALL_IONCUBE
if [ -z $INSTALL_IONCUBE ]; then
	INSTALL_IONCUBE="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_IONCUBE"
echo "---------------------------"
echo ""

echo "Do you want to install Zend Optimizer ? (y/n)"
read -p "(Default: y):" INSTALL_ZEND
if [ -z $INSTALL_ZEND ]; then
	INSTALL_ZEND="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_ZEND"
echo "---------------------------"
echo ""

get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo "Press any key to start install..."
echo "Or Ctrl+C cancel and exit ?"
echo ""
char=`get_char`

if [ -d "$LANMP_PATH/src" ];then
	mv $LANMP_PATH/src/* $LANMP_PATH
fi

echo "---------- Remove and Update ----------"

rpm -e httpd
rpm -e mysql
rpm -e php
yum -y remove httpd
yum -y remove mysql
yum -y remove php
yum -y update

echo "---------- Set timezone ----------"

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

yum -y install ntp
ntpdate -d cn.pool.ntp.org

echo "---------- Disable SeLinux ----------"

if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

echo "---------- Dependent Packages ----------"

sed -i 's/exclude=kernel/#exclude=kernel/g' /etc/yum.conf

yum -y install make cmake autoconf gcc gcc-c++ libtool
yum -y install wget elinks bison
yum -y install openssl openssl-devel
yum -y install zlib zlib-devel
yum -y install freetype freetype-devel
yum -y install libxml2 libxml2-devel
yum -y install libdhash libdhash-devel
yum -y install curl curl-devel
yum -y install libevent libevent-devel
yum -y install ncurses ncurses-devel
yum -y install libc-client libc-client-devel

####################### Extract Function ########################

Extract(){
	local TARBALL_TYPE
	if [ -n $1 ]; then
		SOFTWARE_NAME=`echo $1 | awk -F/ '{print $NF}'`
		TARBALL_TYPE=`echo $1 | awk -F. '{print $NF}'`
		wget -c -t3 -T3 $1
		if [ $? != "0" ];then
			rm -rf $LANMP_PATH/$SOFTWARE_NAME
			wget -c -t3 -T60 $2
			SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
		fi
	else
		SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
		TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
		wget -c -t3 -T3 $2 || exit
	fi
	EXTRACTED_DIR=`tar tf $LANMP_PATH/$SOFTWARE_NAME | tail -n 1 | awk -F/ '{print $1}'`
	case $TARBALL_TYPE in
		gz|tgz)
			tar zxf $LANMP_PATH/$SOFTWARE_NAME && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		bz2|tbz)
			tar jxf $LANMP_PATH/$SOFTWARE_NAME && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		tar|Z)
			tar xf $LANMP_PATH/$SOFTWARE_NAME && cd $LANMP_PATH/$EXTRACTED_DIR || return 1
		;;
		*)
		echo "$SOFTWARE_NAME is wrong tarball type ! "
	esac
}

echo "===================== MySQL Install ===================="

cd $LANMP_PATH
rm -rf /etc/my.cnf /etc/mysql/

groupadd mysql
useradd -g mysql -M -s /bin/false mysql

if [ ! -s mysql-*.tar.gz ]; then
	LATEST_MYSQL_LINK=`elinks ftp://mirror.csclub.uwaterloo.ca/mysql/Downloads/MySQL-5.5/ | awk '/ftp:.+\.[0-9][0-9][a-z]?\.tar\.gz$/{print $2}' | tail -n 1`
	BACKUP_MYSQL_LINK='http://wangyan.org/download/lanmp/mysql-latest.tar.gz'
	Extract ${LATEST_MYSQL_LINK} ${BACKUP_MYSQL_LINK}
else
	tar -zxf mysql-*.tar.gz
	cd mysql-*
fi

cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_ZLIB=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1
make install

cp $LANMP_PATH/conf/my.cnf /etc/my.cnf

cd /usr/local/mysql
scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql
chown -R root:root /usr/local/mysql/.
chown -R mysql /usr/local/mysql/data

cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysql on

echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf
ldconfig

cd /usr/local/mysql/bin
for i in *; do ln -s /usr/local/mysql/bin/$i /usr/bin/$i; done

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $MYSQL_ROOT_PWD

echo "===================== Apache Install ===================="

if [[ "$SOFTWARE" = "2" || "$SOFTWARE" = "3" ]]; then

	echo "---------- Apache ----------"

	cd $LANMP_PATH

	if [ ! -s httpd-*.tar.gz ]; then
#		LATEST_APACHE_LINK=`elinks http://www.apache.org/dist/httpd/ | awk '/http.+[0-9]\.tar\.gz$/{print $2}' | tail -1`
#		BACKUP_APACHE_LINK="http://wangyan.org/download/lanmp/httpd-latest.tar.gz"
		LATEST_APACHE_LINK="http://www.apache.org/dist/httpd/httpd-2.2.22.tar.gz"
		BACKUP_APACHE_LINK="http://wangyan.org/download/lanmp/httpd-2.2.22.tar.gz"
		Extract ${LATEST_APACHE_LINK} ${BACKUP_APACHE_LINK}
	else
		tar -zxf httpd-*.tar.gz
		cd httpd-*/
	fi

	cd srclib/apr
	./configure && make && make install

	cd ../apr-util
	./configure --with-apr=/usr/local/apr
	make && make install
	ldconfig && cd ../../

	./configure  --prefix=/usr/local/apache --enable-mods-shared=most --enable-ssl=shared --with-mpm=prefork --with-apr=/usr/local/apr
	make && make install

	echo "---------- Apache config ----------"

	cd /usr/local/apache/bin/
	for i in *; do ln -s /usr/local/apache/bin/$i /usr/bin/$i; done

	groupadd www
	useradd -g www -M -s /bin/false www

	cp $LANMP_PATH/conf/init.d.httpd /etc/init.d/httpd
	chmod 755 /etc/init.d/httpd
	chkconfig httpd on

	mv /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf.old
	cp $LANMP_PATH/conf/httpd.conf /usr/local/apache/conf/httpd.conf
	chmod 644 /usr/local/apache/conf/httpd.conf

	mv /usr/local/apache/conf/extra/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf.bak
	cp $LANMP_PATH/conf/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf
	chmod 644 /usr/local/apache/conf/extra/httpd-mpm.conf

	mkdir /usr/local/apache/conf/vhosts
	chmod 711 /usr/local/apache/conf/vhosts
	mkdir -p $WEBROOT
	cp $LANMP_PATH/conf/p.php $WEBROOT

	echo "---------- Apache SSL ----------"

	mkdir /usr/local/apache/conf/ssl
	chmod 711 /usr/local/apache/conf/ssl
	cp $LANMP_PATH/conf/server* /usr/local/apache/conf/ssl
	chmod 644 /usr/local/apache/conf/ssl/*

	mv /usr/local/apache/conf/extra/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf.bak
	cp $LANMP_PATH/conf/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
	chmod 644 /usr/local/apache/conf/extra/httpd-ssl.conf
	sed -i 's,WEBROOT,'$WEBROOT',g' /usr/local/apache/conf/extra/httpd-ssl.conf

	if [ "$SOFTWARE" = "2" ]; then
		sed -i 's,#Include conf/extra/httpd-s,Include conf/extra/httpd-s,g' /usr/local/apache/conf/httpd.conf
	fi

	echo "---------- Apache frontend ----------"

	if [ "$SOFTWARE" = "2" ]; then
		sed -i 's/\#Listen 80/Listen 80/g' /usr/local/apache/conf/httpd.conf

		cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
		NameVirtualHost *:80

		<VirtualHost _default_:80>
			ServerAdmin webmaster@example.com
			DocumentRoot "$WEBROOT"
			ServerName 127.0.0.1
			ErrorLog "logs/error_log"
			CustomLog "logs/access_log" combinedio
			<Directory "$WEBROOT">
			    Options +Includes +Indexes
			    php_admin_flag engine ON
			    php_admin_value open_basedir "$WEBROOT:/tmp:/proc"
			</Directory>
		</VirtualHost>

		Include /usr/local/apache/conf/vhosts/*.conf
		EOF
	fi

	if [ "$SOFTWARE" = "3" ]; then

		echo "---------- RPAF ----------"

		cd $LANMP_PATH

		if [ ! -s mod_rpaf-*.tar.gz ]; then
			LATEST_RPAF_LINK="http://stderr.net/apache/rpaf/download/mod_rpaf-0.6.tar.gz"
			BACKUP_RPAF_LINK="http://wangyan.org/download/lanmp/mod_rpaf-latest.tar.gz"
			Extract ${LATEST_RPAF_LINK} ${BACKUP_RPAF_LINK}
		else
			tar zxf mod_rpaf-*.tar.gz
			cd mod_rpaf-*/
		fi
		/usr/local/apache/bin/apxs -i -c -n mod_rpaf-2.0.so mod_rpaf-2.0.c

		echo "---------- Apache backend ----------"

		sed -i 's/\#Listen 127/Listen 127/g' /usr/local/apache/conf/httpd.conf
		sed -i 's/\#LoadModule rpaf/LoadModule rpaf/g' /usr/local/apache/conf/httpd.conf

		cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
		NameVirtualHost 127.0.0.1:8080

		<VirtualHost 127.0.0.1:8080>
			ServerAdmin webmaster@example.com
			DocumentRoot "$WEBROOT"
			ServerName 127.0.0.1
			ErrorLog "logs/error_log"
			CustomLog "logs/access_log" combinedio
			<Directory "$WEBROOT">
				Options +Includes +Indexes
				php_admin_flag engine ON
				php_admin_value open_basedir "$WEBROOT:/tmp:/proc"
			</Directory>
		</VirtualHost>

		Include /usr/local/apache/conf/vhosts/*.conf
		EOF

	fi
fi

echo "===================== PHP5 Install ===================="

echo "---------- libpng ----------"

cd $LANMP_PATH

if [ ! -s libpng-*.tar.gz ]; then
	LATEST_LIBPNG_LINK=`elinks ftp://ftp.simplesystems.org/pub/libpng/png/src/ | awk '/ftp:.+libpng-.+gz$/{print $2}' | tail -1`
	BACKUP_LIBPNG_LINK="http://wangyan.org/download/lanmp/libpng-latest.tar.gz"
	Extract ${LATEST_LIBPNG_LINK} ${BACKUP_LIBPNG_LINK}
else
	tar -zxf libpng-*.tar.gz
	cd libpng-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libjpeg ----------"

cd $LANMP_PATH

if [ ! -s jpegsrc.*.tar.gz ]; then
	LATEST_LIBJPEG_LINK=`elinks http://www.ijg.org/files/ | awk '/http.+jpegsrc.+$/{print $2}' | tail -1`
	BACKUP_LIBJPEG_LINK="http://wangyan.org/download/lanmp/jpegsrc.latest.tar.gz"
	Extract ${LATEST_LIBJPEG_LINK} ${BACKUP_LIBJPEG_LINK}
else
	tar -zxf jpegsrc.*.tar.gz
	cd jpeg-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libiconv ----------"

cd $LANMP_PATH

if [ ! -s libiconv-*.tar.gz ]; then
	LATEST_LIBICONV_LINK=`elinks http://ftp.gnu.org/pub/gnu/libiconv/ | awk '/http.+.gz$/{print $2}' | sort -n -k 4 -t . | tail -1`
	BACKUP_LIBICONV_LINK="http://wangyan.org/download/lanmp/libiconv-latest.tar.gz"
	Extract ${LATEST_LIBICONV_LINK} ${LATEST_LIBICONV_LINK}
else
	tar -zxf libiconv-*.tar.gz
	cd libiconv-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libmcrypt ----------"

cd $LANMP_PATH

if [ ! -s libmcrypt-*.tar.gz ]; then
	LATEST_LIBMCRYPT_LINK="http://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz"
	BACKUP_LIBMCRYPT_LINK="http://wangyan.org/download/lanmp/libmcrypt-latest.tar.gz"
	Extract ${LATEST_LIBMCRYPT_LINK} ${BACKUP_LIBMCRYPT_LINK}
else
	tar -zxf libmcrypt-*.tar.gz
	cd libmcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- mhash ----------"

cd $LANMP_PATH

if [ ! -s mhash-*.tar.gz ]; then
	LATEST_MHASH_LINK="http://nchc.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz"
	BACKUP_MHASH_LINK="http://wangyan.org/download/lanmp/mhash-latest.tar.gz"
	Extract ${LATEST_MHASH_LINK} ${BACKUP_MHASH_LINK}
else
	tar -zxf mhash-0.9.9.9.tar.gz
	cd mhash-*/
fi
./configure --prefix=/usr/local
make && make install

echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

echo "---------- mcrypt ----------"

cd $LANMP_PATH

if [ ! -s mcrypt-*.tar.gz ]; then
	LATEST_MCRYPT_LINK="http://nchc.dl.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz"
	BACKUP_MCRYPT_LINK="http://wangyan.org/download/lanmp/mcrypt-latest.tar.gz"
	Extract ${LATEST_MCRYPT_LINK} ${BACKUP_MCRYPT_LINK}
else
	tar -zxf mcrypt-*.tar.gz
	cd mcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- php5 ----------"

cd $LANMP_PATH

groupadd www-data
useradd -g www-data -M -s /bin/false www-data

if [ "$PHP_VER" = "1" ]; then
	if [ ! -s php-5.2.*.tar.gz ]; then
		LATEST_PHP_LINK="http://us.php.net/distributions/php-5.2.17.tar.gz"
		BACKUP_PHP_LINK="http://wangyan.org/download/lanmp/php-5.2.17.tar.gz"
		Extract ${LATEST_PHP_LINK} ${BACKUP_PHP_LINK}
	else
		tar -zxf php-5.2.*.tar.gz
		cd php-5.2.*/
	fi
else
	if [ ! -s php-5.4.*.tar.gz ]; then
		LATEST_PHP_LINK="http://us.php.net/distributions/php-5.4.4.tar.gz"
		BACKUP_PHP_LINK="http://wangyan.org/download/lanmp/php-latest.tar.gz"
		Extract ${LATEST_PHP_LINK} ${BACKUP_PHP_LINK}
	else
		tar -zxf php-5.4.*.tar.gz
		cd php-5.4.*/
	fi
fi

if [ "$SOFTWARE" != "1" ]; then
	./configure \
	--prefix=/usr/local/php \
	--with-apxs2=/usr/local/apache/bin/apxs \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-zlib \
	--with-png-dir \
	--with-jpeg-dir \
	--with-iconv-dir \
	--with-freetype-dir \
	--with-gd \
	--enable-gd-native-ttf \
	--with-libxml-dir \
	--with-mhash \
	--with-mcrypt \
	--with-curl \
	--with-curlwrappers \
	--with-openssl \
	--with-gettext \
	--with-pear \
	--enable-bcmath \
	--enable-calendar \
	--enable-mbstring \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-exif \
	--enable-xml \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-soap \
	--enable-shmop \
	--enable-mbregex \
	--enable-inline-optimization \
	--enable-zend-multibyte
else
	./configure \
	--prefix=/usr/local/php \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-zlib \
	--with-png-dir \
	--with-jpeg-dir \
	--with-iconv-dir \
	--with-freetype-dir \
	--with-gd \
	--enable-gd-native-ttf \
	--with-libxml-dir \
	--with-mhash \
	--with-mcrypt \
	--with-curl \
	--with-curlwrappers \
	--with-openssl \
	--with-gettext \
	--with-pear \
	--enable-bcmath \
	--enable-calendar \
	--enable-mbstring \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-exif \
	--enable-xml \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-soap \
	--enable-shmop \
	--enable-mbregex \
	--enable-inline-optimization \
	--enable-zend-multibyte \
	--enable-fpm \
	--with-fpm-user=www-data \
	--with-fpm-group=www-data
fi

make ZEND_EXTRA_LIBS='-liconv'
make install

echo "---------- PDO MYSQL Extension ----------"

cd ext/pdo_mysql/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-pdo-mysql=/usr/local/mysql
make && make install

echo "---------- Imap Extension ----------"

cd ../imap/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config  --with-kerberos --with-imap-ssl
make && make install

echo "---------- Memcache Extension ----------"

cd $LANMP_PATH

if [ ! -s memcache-*.tgz ]; then
	LATEST_MEMCACHE_LINK="http://pecl.php.net/get/memcache-2.2.6.tgz"
	BACKUP_MEMCACHE_LINK="http://wangyan.org/download/lanmp/memcache-latest.tgz"
	Extract ${LATEST_MEMCACHE_LINK} ${BACKUP_MEMCACHE_LINK}
else
	tar -zxf memcache-*.tgz
	cd memcache-*/
fi
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-zlib-dir --enable-memcache
make && make install

echo "---------- PHP Config ----------"

cd /usr/local/php/bin
for i in *; do ln -s /usr/local/php/bin/$i /usr/bin/$i; done

cd $LANMP_PATH/php-*/

if [ "$PHP_VER" = "1" ];then
	cp php.ini-recommended /usr/local/php/lib/php.ini
	sed -i 's#; extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/"\nextension = "memcache.so"\nextension = "pdo_mysql.so"\nextension = "imap.so"\n#g' /usr/local/php/lib/php.ini
else
	cp php.ini-production /usr/local/php/lib/php.ini
	sed -i 's#; extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20100525/"\nextension = "memcache.so"\nextension = "pdo_mysql.so"\nextension = "imap.so"\n#g' /usr/local/php/lib/php.ini
fi

sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php/lib/php.ini
sed -i 's/disable_functions =/disable_functions = system,passthru,exec,shell_exec,popen,symlink,dl/g' /usr/local/php/lib/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/php/lib/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 80M/g' /usr/local/php/lib/php.ini
sed -i 's/magic_quotes_gpc = Off/magic_quotes_gpc = On/g' /usr/local/php/lib/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php/lib/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/g' /usr/local/php/lib/php.ini
sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#g' /usr/local/php/lib/php.ini
sed -i 's#;sendmail_path =#sendmail_path = /usr/sbin/sendmail -t -i#g' /usr/local/php/lib/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 3600/g' /usr/local/php/lib/php.ini

if [ "$SOFTWARE" = "2" ] || [ "$SOFTWARE" = "3" ]; then
	/etc/init.d/httpd start
else
	cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod 755 /etc/init.d/php-fpm
	chkconfig php-fpm on

	cp $LANMP_PATH/conf/php-fpm.conf /usr/local/php/etc/php-fpm.conf
	/etc/init.d/php-fpm start
fi

echo "---------- Xcache Extension ----------"

if [ "$INSTALL_XC" = "y" ];then

	cd $LANMP_PATH

	if [ ! -s xcache-*.tar.gz ]; then
		LATEST_XCACHE_LINK="http://xcache.lighttpd.net/pub/Releases/2.0.1/xcache-2.0.1.tar.gz"
		BACKUP_XCACHE_LINK="http://wangyan.org/download/lanmp/xcache-latest.tar.bz2"
		Extract ${LATEST_XCACHE_LINK} ${BACKUP_XCACHE_LINK}
	else
		tar zxf xcache-*.tar.gz
		cd xcache-*/
	fi
	/usr/local/php/bin/phpize
	./configure --enable-xcache --enable-xcache-optimizer --enable-xcache-coverager
	make && make install

	cp -r admin/ /var/www/xcache
	chmod -R 755 /var/www/xcache

	mkdir /tmp/{pcov,phpcore}
	chown www:www /tmp/{pcov,phpcore}
	chmod 700 /tmp/{pcov,phpcore}

	if [ "$PHP_VER" = "1" ]; then
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[xcache-common]
		zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/xcache.so
		EOF
	else
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[xcache-common]
		zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20100525/xcache.so
		EOF
	fi
	cat >>/usr/local/php/lib/php.ini<<-EOF

	[xcache.admin]
	xcache.admin.user = admin
	xcache.admin.pass = e10adc3949ba59abbe56e057f20f883e
	xcache.admin.enable_auth = On
	xcache.test = Off
	xcache.coredump_directory = /tmp/phpcore
	xcache.disable_on_crash = ""

	[xcache]
	xcache.cacher = On
	xcache.size = 256M
	xcache.count = 8
	xcache.slots = 8K
	xcache.ttl = 0
	xcache.gc_interval = 0
	xcache.var_size = 32M
	xcache.var_count = 8
	xcache.var_slots = 8K
	xcache.var_ttl = 0
	xcache.var_maxttl = 0
	xcache.var_gc_interval = 300
	xcache.readonly_protection = Off
	xcache.mmap_path = /dev/zero

	[xcache.optimizer]
	xcache.optimizer = On

	[xcache.coverager]
	xcache.coverager = On
	xcache.coveragedump_directory = /tmp/pcov

	EOF
fi

echo "---------- Ioncube Extension ----------"

cd $LANMP_PATH

if [ "$INSTALL_IONCUBE" = "y" ];then
	if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
		if [ ! -s ioncube_loaders_lin_x86-64.tar.gz ]; then
			LATEST_IONCUBE_LINK="http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
			BACKUP_IONCUBE_LINK="http://wangyan.org/download/lanmp/ioncube_loaders_lin_x86-64.tar.gz"
			Extract ${LATEST_IONCUBE_LINK} ${BACKUP_IONCUBE_LINK}
		else
			tar -zxf ioncube_loaders_lin_x86-64.tar.gz
			cd ioncube/
		fi
	else
		if [ ! -s ioncube_loaders_lin_x86.tar.gz ]; then
			LATEST_IONCUBE_LINK="http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz"
			BACKUP_IONCUBE_LINK="http://wangyan.org/download/lanmp/ioncube_loaders_lin_x86.tar.gz"
			Extract ${LATEST_IONCUBE_LINK} ${BACKUP_IONCUBE_LINK}
		else
			tar -zxf ioncube_loaders_lin_x86.tar.gz
			cd ioncube/
		fi
	fi

	mkdir -p /usr/local/zend/
	if [ "$PHP_VER" = "1" ]; then
		cp ioncube_loader_lin_5.2.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[ioncube loader]
		zend_extension = /usr/local/zend/ioncube_loader_lin_5.2.so
		EOF
	else
		cp ioncube_loader_lin_5.4.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF
		[ioncube loader]
		zend_extension = /usr/local/zend/ioncube_loader_lin_5.4.so
		EOF
	fi
fi

echo "---------- ZendOptimizer Extension ----------"

cd $LANMP_PATH

if [ "$INSTALL_ZEND" = "y" ];then

	if [ "$PHP_VER" = "1" ]; then
		if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
			if [ ! -s ZendOptimizer-*-linux-glibc23-x86_64.tar.gz ]; then
				LATEST_ZEND_LINK="http://downloads.zend.com/optimizer/3.3.9/ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz"
				BACKUP_ZEND_LINK="http://wangyan.org/download/lanmp/ZendOptimizer-latest-linux-glibc23-x86_64.tar.gz"
				Extract ${LATEST_ZEND_LINK} ${BACKUP_ZEND_LINK}
			else
				tar zxf ZendOptimizer-*-linux-glibc23-x86_64.tar.gz
				cd ZendOptimizer-*-linux-glibc23-x86_64/
			fi
		else
			if [ ! -s ZendOptimizer-*-linux-glibc23-i386.tar.gz ]; then
				LATEST_ZEND_LINK="http://downloads.zend.com/optimizer/3.3.9/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz"
				BACKUP_ZEND_LINK="http://wangyan.org/download/lanmp/ZendOptimizer-latest-linux-glibc23-i386.tar.gz"
				Extract ${LATEST_ZEND_LINK} ${BACKUP_ZEND_LINK}
			else
				tar zxf ZendOptimizer-*-linux-glibc23-i386.tar.gz
				cd ZendOptimizer-*-linux-glibc23-i386/
			fi
		fi
		mkdir -p /usr/local/zend/
		cp data/5_2_x_comp/ZendOptimizer.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF

		[Zend Optimizer]
		zend_extension = /usr/local/zend/ZendOptimizer.so
		zend_loader.enable = 1
		EOF
	else
		if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
			if [ ! -s ZendGuardLoader-php-*-linux-glibc23-x86_64.tar.gz ]; then
				LATEST_GUARD_LINK="http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz"
				BACKUP_GUARD_LINK="http://wangyan.org/download/lanmp/ZendGuardLoader-php-latest-linux-glibc23-x86_64.tar.gz"
				Extract ${LATEST_GUARD_LINK} ${BACKUP_GUARD_LINK}
			else
				tar -zxf ZendGuardLoader-php-*-linux-glibc23-x86_64.tar.gz
				cd ZendGuardLoader-php-*-linux-glibc23-x86_64/
			fi
		else
			if [ ! -s ZendGuardLoader-php-*-linux-glibc23-i386.tar.gz ]; then
				LATEST_GUARD_LINK="http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz"
				BACKUP_GUARD_LINK="http://wangyan.org/download/lanmp/ZendGuardLoader-php-latest-linux-glibc23-i386.tar.gz"
				Extract ${LATEST_GUARD_LINK} ${BACKUP_GUARD_LINK}
			else
				tar -zxf ZendGuardLoader-php-*-linux-glibc23-i386.tar.gz
				cd ZendGuardLoader-php-*-linux-glibc23-i386/
			fi
		fi
		mkdir -p /usr/local/zend/
		cp php-5.3.x/ZendGuardLoader.so /usr/local/zend/
		cat >>/usr/local/php/lib/php.ini<<-EOF

		[Zend GuardLoader]
		zend_extension = /usr/local/zend/ZendGuardLoader.so
		zend_loader.enable = 1
		EOF
	fi
fi

if [ "$SOFTWARE" = "2" ] || [ "$SOFTWARE" = "3" ]; then
	/usr/local/apache/bin/httpd -k restart
else
	/etc/init.d/php-fpm restart
fi

echo "===================== Nginx Install ===================="

if [ "$SOFTWARE" != "2" ]; then

	groupadd www
	useradd -g www -M -s /bin/false www

	echo "---------- Pcre ----------"

	cd $LANMP_PATH

	if [ ! -s pcre-*.tar.gz ]; then
		LATEST_PCRE_LINK=`elinks ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/ | awk '/ftp:.+gz$/{print $2}' | tail -1`
		BACKUP_PCRE_LINK="http://wangyan.org/download/lanmp/pcre-latest.tar.gz"
		Extract ${LATEST_PCRE_LINK} ${BACKUP_PCRE_LINK}
	else
		tar -zxf pcre-*.tar.gz
		cd pcre-*
	fi
	./configure
	make && make install
	ldconfig

	echo "---------- Nginx ----------"

	cd $LANMP_PATH
	mkdir -p /var/tmp/nginx
	
	if [ ! -s nginx-*.tar.gz ]; then
		LATEST_NGINX_LINK=`elinks http://nginx.org/download/ | awk '/http.+gz$/{print $2}' | tail -1`
		BACKUP_NGINX_LINK="http://wangyan.org/download/lanmp/nginx-latest.tar.gz"
		Extract ${LATEST_NGINX_LINK} ${BACKUP_NGINX_LINK}
	else
		tar -zxf nginx-*.tar.gz
		cd nginx-*/
	fi

	./configure \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/lock/nginx.lock \
	--user=www \
	--group=www \
	--with-http_ssl_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_realip_module \
	--with-http_gzip_static_module \
	--with-http_stub_status_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-pcre \
	--with-debug \
	--with-ipv6 \
	--http-client-body-temp-path=/var/tmp/nginx/client \
	--http-proxy-temp-path=/var/tmp/nginx/proxy \
	--http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
	--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
	--http-scgi-temp-path=/var/tmp/nginx/scgi
	make && make install

	echo "---------- Nginx Config----------"

	mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
	cp $LANMP_PATH/conf/nginx.conf /usr/local/nginx/conf/nginx.conf
	chmod 644 /usr/local/nginx/conf/nginx.conf

	mkdir /usr/local/nginx/conf/ssl
	chmod 711 /usr/local/nginx/conf/ssl
	cp $LANMP_PATH/conf/server* /usr/local/nginx/conf/ssl/
	chmod 644 /usr/local/nginx/conf/ssl/*

	mkdir /usr/local/nginx/conf/vhosts
	chmod 711 /usr/local/nginx/conf/vhosts
	mkdir /usr/local/nginx/logs/localhost

	if [ "$SOFTWARE" = "1" ]; then
		cp $LANMP_PATH/conf/nginx-vhost-original.conf /usr/local/nginx/conf/vhosts/localhost.conf
	else
		cp $LANMP_PATH/conf/nginx-vhost-proxy.conf /usr/local/nginx/conf/vhosts/localhost.conf
	fi
	chmod 644 /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,www.DOMAIN,,g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,DOMAIN/,localhost/,g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,DOMAIN,'$IP_ADDRESS',g' /usr/local/nginx/conf/vhosts/localhost.conf
	sed -i 's,ROOTDIR,'$WEBROOT',g' /usr/local/nginx/conf/vhosts/localhost.conf

	if [ ! -d $WEBROOT ]; then
		mkdir -p $WEBROOT
		cp $LANMP_PATH/conf/p.php $WEBROOT
	fi

	cp $LANMP_PATH/conf/init.d.nginx /etc/init.d/nginx
	chmod 755 /etc/init.d/nginx
	chkconfig nginx on

	ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
	/etc/init.d/nginx start
fi

echo "================phpMyAdmin Install==============="

cd $LANMP_PATH

if [ ! -s phpMyAdmin-*-all-languages.tar.gz ]; then
	PMA_LINK="http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/"
	PMA_VERSION=`elinks http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | sort -n | grep -iv 'rc' | tail -1`
	LATEST_PMA_LINK="${PMA_LINK}${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"
	BACKUP_PMA_LINK="http://wangyan.org/download/lanmp/phpMyAdmin-latest-all-languages.tar.gz"
	Extract ${LATEST_PMA_LINK} ${BACKUP_PMA_LINK}
	mkdir -p $WEBROOT/phpmyadmin
	mv * $WEBROOT/phpmyadmin
else
	tar -zxf phpMyAdmin-*-all-languages.tar.gz -C $WEBROOT
	mv $WEBROOT/phpMyAdmin-*-all-languages $WEBROOT/phpmyadmin
fi

cp $LANMP_PATH/conf/config.inc.php $WEBROOT/phpmyadmin/config.inc.php
sed -i 's/PMAPWD/'$PMAPWD'/g' $WEBROOT/phpmyadmin/config.inc.php

cp $LANMP_PATH/conf/control_user.sql /tmp/control_user.sql
sed -i 's/PMAPWD/'$PMAPWD'/g' /tmp/control_user.sql
/usr/local/mysql/bin/mysql -u root -p$MYSQL_ROOT_PWD -h 127.0.0.1 < /tmp/control_user.sql

if [ -s $WEBROOT/phpmyadmin/scripts/create_tables.sql ]; then
	cp $WEBROOT/phpmyadmin/scripts/create_tables.sql /tmp/create_tables.sql
else
	cp $WEBROOT/phpmyadmin/examples/create_tables.sql /tmp/create_tables.sql
fi

cat >>update_mysql.sh<<EOF
create database phpmyadmin;
use phpmyadmin;
source /tmp/create_tables.sql;
EOF

cat update_mysql.sh | mysql -u root -p$MYSQL_ROOT_PWD
rm -rf /usr/local/mysql/data/test/
rm update_mysql.sh
rm /tmp/create_tables.sql

clear
echo ""
echo "===================== Install completed ====================="
echo ""
echo "LANMP install completed!"
echo "For more information please visit http://wangyan.org/blog/lanmp.html"
echo ""
echo "Server ip address: $IP_ADDRESS"
echo "MySQL root password: $MYSQL_ROOT_PWD"
echo "MySQL pma password: $PMAPWD"
echo ""
echo "php config file at: /usr/local/php/lib/php.ini"
echo "Pear config file at: /usr/local/php/etc/pear.conf"
[ "$SOFTWARE" = "1" ] && echo "php-fpm config file at: /usr/local/php/etc/php-fpm.conf"
[ "$SOFTWARE" != "2" ] && echo "nginx config file at: /usr/local/nginx/conf/nginx.conf"
[ "$SOFTWARE" != "1" ] && echo "httpd config file at: /usr/local/apache/conf/httpd.conf"
echo ""
echo "WWW root dir: $WEBROOT"
echo "PHP prober: http://$IP_ADDRESS/p.php"
echo "phpMyAdmin: http://$IP_ADDRESS/phpmyadmin/"
echo ""
echo "============================================================="
echo ""
