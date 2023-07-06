ARG ALPINE_VERSION=3.18
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Zarif Fathurrahman Rani <code@trafex.nl>"
LABEL Description="Blog container zarifhomelab with Nginx 1.24 & PHP 8.1 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  php81-mysqli \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-xml \
  php81-xmlreader \
  supervisor \
  git \
  openssh

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the blog user
RUN adduser -D blog
RUN chown -R blog.blog /var/www/html /run /var/lib/nginx /var/log/nginx

# setup user and ssh key 
USER blog
RUN mkdir /home/blog/.ssh/
COPY --chown=blog id_webhook /home/blog/.ssh/id_rsa
RUN chmod 600 /home/blog/.ssh/id_rsa

RUN touch /home/blog/.ssh/known_hosts
# change localhost to your gitea server domain or ip address
RUN ssh-keyscan -p 22 localhost >> /home/blog/.ssh/known_hosts

# setup folder
WORKDIR /var/www/html
RUN git clone ssh://git@localhost:22/zarif/_site.git

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
