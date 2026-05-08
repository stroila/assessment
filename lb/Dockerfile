FROM registry.access.redhat.com/ubi9/nginx-126
USER 0
# Add application sources
#ADD nginx/nginx.conf "${NGINX_CONF_PATH}"
#ADD nginx/nginx-default-cfg/*.conf "${NGINX_DEFAULT_CONF_PATH}"
#ADD nginx/nginx-cfg/*.conf "${NGINX_CONFIGURATION_PATH}"
#ADD nginx/*.html .

RUN mkdir -p /opt/nginx /etc/nginx.d /etc/nginx.default.d /etc/nginx/cert
RUN nginx -t

EXPOSE 8443

COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]

