FROM nginx

COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/ssl
COPY ssl/kibana.cartalk.com.crt /etc/nginx/ssl/kibana.cartalk.com.crt 
COPY ssl/kibana.cartalk.com.key /etc/nginx/ssl/kibana.cartalk.com.key 
RUN chmod 600 /etc/nginx/ssl/kibana.cartalk.com.key 
COPY kibana.htpasswd /etc/nginx/conf.d/kibana.htpasswd
