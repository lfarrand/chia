FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV key_path="null"
ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3 vim nano

RUN echo "Cloning chia-blockchain"
RUN git clone https://github.com/Chia-Network/chia-blockchain.git -b latest \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

RUN echo "Installing chiabot"
RUN mkdir -p chiabot \
&& cd chiabot/ \
&& wget https://github.com/joaquimguimaraes/chiabot/releases/download/v1.3.0-3/chiabot-linux-amd64.tar.gz \
&& tar -xf chiabot-linux-amd64.tar.gz \
&& rm -rf config.json \
&& rm -rf chiabot-linux-amd64.tar.gz

RUN ls -al /chiabot

WORKDIR /chia-blockchain
RUN mkdir /plots
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
