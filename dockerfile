FROM alpine:3.13
CMD ["/bin/sh"]
LABEL maintainer=Damian
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories  \
	&& apk update  \
	&& apk upgrade  \
	&& apk add --no-cache ca-certificates logrotate shadow bash bc findutils coreutils openssl php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl php7-zlib php7-xml php7-phar php7-dom php7-xmlreader php7-ctype php7-mbstring php7-gd curl nginx libxml2-utils
RUN wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz -O s6-overlay.tar.gz  \
	&& tar xfv s6-overlay.tar.gz -C /  \
	&& rm -r s6-overlay.tar.gz
RUN apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing mergerfs  \
	&& sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
VOLUME [/unionfs]
VOLUME [/config]
VOLUME [/move]
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip  \
	&& unzip rclone.zip  \
	&& rm rclone.zip  \
	&& mv rclone*/rclone /usr/bin  \
	&& rm -r rclone*  \
	&& mkdir -p /mnt/tdrive  \
	&& mkdir -p /mnt/gdrive  \
	&& mkdir -p /move/Media  \
#	&& chown 911:911 /unionfs  \
#	&& chown 911:911 /config  \
#	&& chown -hR 911:911 /move  \
	&& chown -hR 911:911 /mnt

RUN addgroup -g 911 abc  \
	&& adduser -u 911 -D -G abc abc

RUN mkdir -p /app \
  && mkdir -p /etc/cont-init.d \
  && mkdir -p /etc/logrotate.d \
  && mkdir -p /etc/services.d

COPY /app /app
COPY /etc/cont-init.d /etc/cont-init.d
COPY /etc/logrotate.d /etc/logrotate.d
COPY /etc/services.d /etc/services.d

RUN cd /app  \
	&& chmod +x gdrive/uploader.sh  \
	&& chmod +x gdrive/upload.sh  \
	&& chmod +x tdrive/uploader.sh  \
	&& chmod +x tdrive/upload.sh  \
	&& chmod +x plex/plexstreams.sh  \
	&& chmod +x mergerfs.sh  \
	&& chmod +x debug.sh  \
	&& chown 911:911 gdrive/uploader.sh  \
	&& chown 911:911 gdrive/upload.sh  \
	&& chown 911:911 tdrive/uploader.sh  \
	&& chown 911:911 tdrive/upload.sh  \
	&& chown 911:911 plex/plexstreams.sh  \
	&& chown 911:911 mergerfs.sh  \
	&& chown 911:911 debug.sh

RUN mkdir -p /var/www/html \
  && mkdir -p /etc/nginx \
  && mkdir -p /etc/php7/php-fpm.d \
  && mkdir -p /etc/php7/conf.d

COPY /var/www/html /var/www/html
COPY /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY /etc/php7/php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf
COPY /etc/php7/conf.d/zzz_custom.ini /etc/php7/conf.d/zzz_custom.ini

EXPOSE 8080
ENV ADDITIONAL_IGNORES=null MOVE_BASE=Media

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
      CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1

ENTRYPOINT ["/init"]