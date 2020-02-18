#!/bin/bash -l

/bin/find /var/log/httpd/www.cartalk.com -mtime +100 -delete
