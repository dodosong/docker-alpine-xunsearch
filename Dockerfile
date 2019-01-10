# xunsearch-alpine docker
# created by dodosong.20190108
#
# BUILD COMMAND:
# docker build -f Dockerfile  -t dodosong/xunsearch:alpine .
#
# START COMMAND:
# docker run -d --name xunsearch -p 8383:8383 -p 8384:8384 \
# -v /var/xunsearch/data:/usr/local/xunsearch/data dodosong/xunsearch:alpine
#

FROM alpine:3.8
LABEL maintainer="dodosong <dodosong@gmail.com>" version="1.0"

## Change repositories, add dnspod's dns for china, apk update
RUN  set -ex \
  && echo -e 'nameserver 119.29.29.29' >> /etc/resolv.conf \
  && sed -i 's/http[s]*:\/\/dl-cdn.alpinelinux.org/https:\/\/mirror.tuna.tsinghua.edu.cn/' /etc/apk/repositories \
  && apk update

## --build-arg timezone=Asia/Shanghai
RUN apk --update add tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

## ---------------
## Install build tools.  alpine-sdk contains build-base and build-base contains gcc,libc,make,g++
RUN apk add --no-cache gcc tar make g++ bzip2 zlib-dev

## Install xunsearch and modify xs-ctl.sh 
RUN cd /root && rm -rf xunsearch-* \
  && wget -qO - http://www.xunsearch.com/download/xunsearch-full-latest.tar.bz2 | tar xj \
  && cd /root/xunsearch-full-* \
  && sh setup.sh --prefix=/usr/local/xunsearch \
  && echo '' >> /usr/local/xunsearch/bin/xs-ctl.sh \
  && echo 'tail -f /dev/null' >> /usr/local/xunsearch/bin/xs-ctl.sh

## Clean cache and remove some build tools
RUN apk del -r --purge make g++ bzip2 zlib-dev \
  && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

WORKDIR /usr/local/xunsearch
RUN echo "#!/bin/sh" > bin/xs-docker.sh \
    && echo "rm -f tmp/pid.*" >> bin/xs-docker.sh \
    && echo "echo -n > tmp/docker.log" >> bin/xs-docker.sh \
    && echo "bin/xs-indexd -l tmp/docker.log -k start" >> bin/xs-docker.sh \
    && echo "sleep 1" >> bin/xs-docker.sh \
    && echo "bin/xs-searchd -l tmp/docker.log -k start" >> bin/xs-docker.sh \
    && echo "sleep 1" >> bin/xs-docker.sh \
    && echo "tail -f tmp/docker.log" >> bin/xs-docker.sh

## Configure it
VOLUME ["/usr/local/xunsearch/data"]
EXPOSE 8383
EXPOSE 8384

## Set ENTRYPOINT and CMD
ENTRYPOINT ["sh"]
CMD ["bin/xs-docker.sh"]
