FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV key_path="null"
ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plot_dirs="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3 vim nano rsync

RUN echo "Cloning chia-blockchain"
RUN git clone https://github.com/Chia-Network/chia-blockchain.git -b latest --recurse-submodules
WORKDIR /chia-blockchain
RUN chmod +x install.sh
RUN /usr/bin/bash install.sh

RUN echo "Installing farmr"
RUN mkdir -p farmr
WORKDIR /farmr
COPY downloadfarmr.sh .
RUN chmod +x downloadfarmr.sh
RUN /usr/bin/bash downloadfarmr.sh

WORKDIR /chia-blockchain
RUN mkdir /plots
COPY entrypoint.sh .

ENTRYPOINT ["bash", "./entrypoint.sh"]
