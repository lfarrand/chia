FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV TZ="Europe/London"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y bc curl lsb-release python3 tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils python-is-python3 vim tzdata nano && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

ARG BRANCH=latest

RUN echo "Cloning chia-blockchain branch ${BRANCH}"
RUN git clone --branch ${BRANCH} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& /usr/bin/sh ./install.sh

RUN echo "Installing farmr"
RUN mkdir -p farmr
WORKDIR /farmr
COPY downloadfarmr.sh .
RUN chmod +x downloadfarmr.sh
RUN /usr/bin/bash downloadfarmr.sh

ENV PATH=/chia-blockchain/venv/bin:$PATH
WORKDIR /chia-blockchain

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
