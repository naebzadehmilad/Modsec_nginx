#!/bin/bash

nginx_version=1.25.0
geoip_module_path="https://github.com/leev/ngx_http_geoip2_module.git"
nginx_source_dir="nginx-$nginx_version"
module_build_dir="./tmp/geoip_module_build"
nginx_install_dir="./tmp/"
geoip_module_version="3.3"

install_debian_dependencies() {
    echo "Installing dependencies for Debian/Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev libmaxminddb-dev libmaxminddb0 libmaxminddb-dev mmdb-bin build-essential libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libxslt-dev libgd-dev

}


if [ -f /etc/debian_version ]; then
    install_debian_dependencies
else
    echo "Unsupported OS. Please install dependencies manually."
    exit 1
fi

mkdir -p $module_build_dir
cd $module_build_dir || exit 1

echo "Downloading Nginx $nginx_version source..."
wget "http://nginx.org/download/nginx-$nginx_version.tar.gz" || { echo "Failed to download Nginx."; exit 1; }
tar -xzvf "nginx-$nginx_version.tar.gz" || { echo "Failed to extract Nginx."; exit 1; }

if [ -d "ngx_http_geoip2_module" ]; then
    echo "Removing existing GeoIP module directory..."
    rm -rf ngx_http_geoip2_module
fi

echo "Downloading GeoIP module..."
git clone $geoip_module_path
cd ngx_http_geoip2_module || exit 1

cd "../nginx-$nginx_version" || exit 1

echo "Configuring Nginx with GeoIP module and other options..."
./configure --prefix=$nginx_install_dir \
            --add-dynamic-module=../ngx_http_geoip2_module \
            --with-pcre \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_gzip_static_module \
            --with-http_stub_status_module \
            --with-http_image_filter_module=dynamic \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-$nginx_version=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
            --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' \
            --with-debug \
            --with-compat \
            --with-pcre-jit \
            --with-http_realip_module \
            --with-http_auth_request_module \
            --with-http_dav_module \
            --with-http_slice_module \
            --with-threads \
            --with-http_addition_module \
            --with-http_gunzip_module \
            --with-http_sub_module \
            --with-http_xslt_module=dynamic \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-mail=dynamic \
            --with-mail_ssl_module

echo "Compiling Nginx..."
make || { echo "Make failed. Please check the configuration and source files."; exit 1; }
sudo make install || { echo "Make install failed. Please check permissions and configuration."; exit 1; }

module_path=$(find $nginx_install_dir -name '*.so')


echo "Done."
