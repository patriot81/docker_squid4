#base image
FROM alpine
#add source from offical site
ADD http://www.squid-cache.org/Versions/v4/squid-4.8.tar.gz /tmp/ 
#extract source and remove downloaded file
RUN tar -xzvf /tmp/squid-4.8.tar.gz && rm /tmp/squid-4.8.tar.gz
#install compile environment 
RUN apk add --no-cache --update g++ make perl openssl-dev
#change dir, configure, make and make install
#--disable-arch-native for qnap support
RUN cd /squid-4.8 && ./configure --disable-arch-native --with-openssl --enable-ssl-crtd --enable-icap-client && make && make install && make clean 

#dest image
FROM alpine
#install lib
RUN apk add --no-cache --update libstdc++
#copy build from old container
COPY --from=0 /usr/local/squid /usr/local/squid
#add icap conf
COPY squid-icap.conf /usr/local/squid/etc
#include the squid-icap.conf
RUN echo "include /usr/local/squid/etc/squid-icap.conf" >> /usr/local/squid/etc/squid.conf
#make writeable for squid process
RUN chown nobody:nobody /usr/local/squid/var/logs/
#open port
EXPOSE 3128/tcp
#check cache_mgr for http response code
HEALTHCHECK --interval=1m --timeout=10s \
  CMD /usr/local/squid/bin/squidclient mgr: | head -1 | grep "HTTP/1.1 200 OK"

#run application
CMD ["/usr/local/squid/sbin/squid","--foreground"]
