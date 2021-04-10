# README
xxd is not appering Ubuntu 16.04 LTS(xenial), so you need to copy xxd binary from 18.04 LTS(bionic). 

1. Copy xxd binary to your docker build directory. 
2. Change your Dockerfile
Please add these two commands in your Dockerfile to copy xxd from Host to contaier.

COPY --chown=root:root xxd /usr/local/xxd
RUN chmod +x /usr/local/xxd

