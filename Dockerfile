# xunsearch-alpine docker
# created by dodosong.20190108
#
# START COMMAND:

# docker run -d --name xunsearch -p 8383:8383 -p 8384:8384 \
# -v /var/xunsearch/data:/usr/local/xunsearch/data hightman/xunsearch:latest
#

FROM alpine:3.8
MAINTAINER dodosong, dodosong@gmail.com

# Change repositories 
RUN echo 'https://mirrors.ustc.edu.cn/alpine/edge/main' > /etc/apk/repositories \
 && echo 'https://mirrors.ustc.edu.cn/alpine/edge/community' >> /etc/apk/repositories \
 && echo 'https://mirrors.ustc.edu.cn/alpine/edge/testing' >> /etc/apk/repositories \
&& apk update \
&& apk add alpine-sdk bzip2 zlib-dev \
&& cd /root && rm -rf xunsearch-* \
&& wget -qO - http://www.xunsearch.com/download/xunsearch-full-dev.tar.bz2 | tar xj \
&& cd /root/xunsearch-full-* \
&& sh setup.sh --prefix=/usr/local/xunsearch \
&& echo '' >> /usr/local/xunsearch/bin/xs-ctl.sh \
&& echo 'tail -f /dev/null' >> /usr/local/xunsearch/bin/xs-ctl.sh

# Configure it
VOLUME ["/usr/local/xunsearch/data"]
EXPOSE 8383
EXPOSE 8384

WORKDIR /usr/local/xunsearch
RUN echo "#!/bin/sh" > bin/xs-docker.sh \
    && echo "rm -f tmp/pid.*" >> bin/xs-docker.sh \
    && echo "echo -n > tmp/docker.log" >> bin/xs-docker.sh \
    && echo "bin/xs-indexd -l tmp/docker.log -k start" >> bin/xs-docker.sh \
    && echo "sleep 1" >> bin/xs-docker.sh \
    && echo "bin/xs-searchd -l tmp/docker.log -k start" >> bin/xs-docker.sh \
    && echo "sleep 1" >> bin/xs-docker.sh \
    && echo "tail -f tmp/docker.log" >> bin/xs-docker.sh

ENTRYPOINT ["sh"]
CMD ["bin/xs-docker.sh"]
