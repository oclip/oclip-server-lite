FROM openresty/openresty:centos

LABEL maintainer="hanxi <hanxi.info@gmail.com>"

RUN /usr/local/openresty/bin/opm get fperrad/lua-messagepack

ADD ./oclipctrl.lua /bin/oclipctrl
RUN chmod +x /bin/oclipctrl

RUN mkdir -p /data/oclip_upload && chmod 777 /data/oclip_upload

