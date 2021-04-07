# 2020-Jan-23 snakajim@arm.com
# Used for building x86_64/ubuntu:18.04 container
#
# 1. Preparation
# Save this "Dockerfile" in your current working directry then,
# $> docker run --rm --privileged multiarch/qemu-user-static:register --reset
#
# 2. Build 
# $> docker build --rm -t ubuntu:18.04_test .
#
# 3. Run container for testing
# $> docker run --rm -t ubuntu:18.04_test uname -m
# aarch64
#
FROM multiarch/qemu-user-static:x86_64-aarch64 as qemu
FROM ubuntu:18.04
COPY --from=qemu /usr/bin/qemu-x86_64-static /usr/bin
