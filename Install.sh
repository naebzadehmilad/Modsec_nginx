#!/bin/bash
path_repo=/etc/apt/sources.list.d/ondrej-ubuntu-nginx-mainline-*.list
repo="deb http://ppa.launchpad.net/ondrej/nginx-mainline/ubuntu focal main #### \n  deb-src http://ppa.launchpad.net/ondrej/nginx-mainline/ubuntu/ focal main"
source_path=/opt/nginx_src
modesecurity_path=/opt/nginx_src/mode_security
nginx_connector=/opt/nginx_src/mode_security_connector
nginx_version=nginx-1.21.6
isInFile=$(cat /etc/nginx/nginx.conf | grep -c "ngx_http_modsecurity_module.so")
BARONE='###########################################################################'

barone() {
	for i in {1..20}; do
                echo -ne "\r${BARONE:0:$i}"
                sleep .1
        done
	        echo -en "\n\n"
}


checkdir(){
	
	echo deb-src http://ir.archive.ubuntu.com/ubuntu focal main restricted >> /etc/apt/sources.list
	
	mkdir -p $source_path $modesecurity_path $nginx_connector

        if [ -z "$(ls -A $modesecurity_path)" ];  
        then
                echo -en "\n\n\n\n\n\n\n"
                git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity $modesecurity_path  
        else 

                 echo "$modesecurity_path is NOT empty"
        fi

	if [ -z "$(ls -A $nginx_connector)" ];
        then
                git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git $nginx_connector

        else
                echo "$nginx_connector is NOT empty"
        fi


}

dependencies() {
	echo "nameserver 185.51.200.2" > /etc/resolv.conf
	sudo apt install -y make gcc build-essential autoconf automake  libtool\
	libfuzzy-dev ssdeep gettext pkg-config libcurl4-openssl-dev \
	liblua5.3-dev libpcre3 libpcre3-dev libxml2 libxml2-dev libyajl-dev \
	doxygen libcurl4 libgeoip-dev libssl-dev zlib1g-dev libxslt-dev liblmdb-dev \
	libpcre++-dev libgd-dev && \
	sudo add-apt-repository ppa:ondrej/nginx-mainline -y && \
	apt update && \
	apt install -y nginx-core nginx-common nginx nginx-full && \
	echo -en $repo > $path_repo && apt update && \
	cd $source_path  &&  apt source nginx && ls -la $source_path && nginx -v 
	apt install libmodsecurity3 -y 	
	cd $modesecurity_path ; git submodule init && git submodule update && ./build.sh && ./configure  && make -j4 && make install 
}
init() {

	cd $source_path ; apt build-dep -y nginx 
	apt install uuid-dev -y 
	cd $source_path/$nginx_version ; ./configure --with-compat --add-dynamic-module=$nginx_connector &&   make modules 
	if [ $isInFile -eq 0 ]; then
        	sed  -i '1i  load_module modules/ngx_http_modsecurity_module.so; ' $nginx_conf
	else 
		echo "skip....."
	fi
	cp $source_path/$nginx_version/objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/ && \
	if [ ! -d "/etc/nginx/modsec/" ] 
	then
		mkdir -p "/etc/nginx/modsec/"
	fi
	cp $modesecurity_path/modsecurity.conf-recommended /etc/nginx/modsec/main.conf  && nginx -t 
}
barone
checkdir
barone
dependencies
barone
init

systemctl enable nginx && systemctl start nginx
