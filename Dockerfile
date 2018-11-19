FROM ubuntu:16.04

# Update Ubuntu Software repository
RUN apt-get update

# Basics
RUN apt-get install -y \
    git \
    curl \
    unzip \
    nano \
    mc \
    cron \
    python-software-properties \
    software-properties-common \
    language-pack-en

# Install nginx, php7 and composer
ENV LANG=en_GB.UTF-8
RUN add-apt-repository -y -u ppa:ondrej/php
RUN apt-get update -y
RUN apt-get install -y nginx-extras
RUN apt-get install -y php7.0 php7.0-fpm php7.0-dev php7.0-bcmath \
php7.0-common php7.0-curl php7.0-gd php7.0-mbstring php7.0-mcrypt \
php7.0-pdo php7.0-mysql php7.0-xml php7.0-xmlrpc php7.0-xsl \
php7.0-zip php7.0-soap php7.0-phpdbg php7.0-opcache php7.0-json \
php7.0-intl php7.0-json php7.0-iconv php7.0-gmp

# MaxminDB
#RUN git clone --recursive https://github.com/maxmind/libmaxminddb
#RUN cd libmaxminddb \
#    && ./bootstrap \
#    && ./configure \
#    && make && make install && ldconfig \
#    && cd ext && phpize && ./configure && make && make install

#RUN echo 'extension=maxminddb.so' > /etc/php/7.0/fpm/php.ini
    
RUN mkdir -p /data/nginx/cache
RUN rm -f /etc/nginx/sites-enabled/default
COPY ./nginx.conf.sample  /etc/nginx/sites-enabled/default

RUN sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 1024M/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 1024M/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/; max_input_vars = .*/max_input_vars = 10000/" /etc/php/7.0/fpm/php.ini

RUN echo 'extension=php_gmp.so' > /etc/php/7.0/fpm/php.ini

RUN mkdir -p /usr/src/tmp/ioncube && \
    curl -fSL "http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz" -o /usr/src/tmp/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xfz /usr/src/tmp/ioncube_loaders_lin_x86-64.tar.gz -C /usr/src/tmp/ioncube && \
    mkdir -p  /usr/lib/php/20151012 && \
    cp /usr/src/tmp/ioncube/ioncube/ioncube_loader_lin_7.0.so /usr/lib/php/20151012/ioncube_loader_lin_7.0.so && \
    rm -Rf /usr/src/tmp/ioncube

RUN echo 'zend_extension=/usr/lib/php/20151012/ioncube_loader_lin_7.0.so' > /etc/php/7.0/fpm/php.ini
RUN echo 'zend_extension=/usr/lib/php/20151012/ioncube_loader_lin_7.0.so' > /etc/php/7.0/cli/php.ini
	
# Mailhog Settings

RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /etc/php/7.0/fpm/php.ini
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /etc/php/7.0/cli/php.ini

RUN curl -sS https://getcomposer.org/installer | php;
RUN mv composer.phar /usr/bin/composer

# COPY ./docker/auth.json /var/www/.composer/
# COPY ./composer.json /var/www/html/composer.json
# RUN chsh -s /bin/bash www-data
# RUN chown -R www-data:www-data /var/www
# RUN su www-data -c "cd /var/www/html && composer install"
# RUN cd /var/www/html \
#     && find . -type d -exec chmod 770 {} \; \
#    && find . -type f -exec chmod 660 {} \; \
#    && chmod u+x bin/magento

RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php


WORKDIR /var/www/html

EXPOSE 80 443

# COPY ./nginx.conf.sample /var/www/html/nginx.conf.sample

CMD service cron start && service php7.0-fpm start && nginx -g "daemon off;"
