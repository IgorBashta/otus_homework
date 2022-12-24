FROM nginx:1.22

RUN apt update -y

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
