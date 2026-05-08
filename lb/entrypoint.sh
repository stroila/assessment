#!/bin/bash

set -e

# Copy config
cp /opt/nginx/nginx.conf /etc/nginx
cp /opt/nginx/nginx-cfg/* /etc/nginx.d
cp /opt/nginx/cert/* /etc/nginx/cert

# Test the config
nginx -t

nginx -g 'daemon off;'

