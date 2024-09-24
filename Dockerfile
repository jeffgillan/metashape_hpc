FROM nvcr.io/nvidia/cudagl:11.4.1-runtime-ubuntu20.04

USER root

LABEL authors="Jeffrey Gillan"
LABEL maintainer="jgillan@arizona.edu"

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user
RUN /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV DEBIAN_FRONTEND=noninteractive
 
# Install libraries/dependencies
RUN apt-get update &&            \
    apt-get install -y           \
      software-properties-common \
      libatk-adaptor \
      libcairo2-dev \
      libcanberra-dev libcanberra-gtk-module libcanberra-gtk3-module \
      libgl1-mesa-glx libglu1 \     
      libjpeg-turbo8 libjpeg-turbo8-dev \
      libpng-dev \
      libssl-dev \                
      gcc \
      #gcc-6 \
      mesa-utils \
      gtk2.0 \
      make \
      pixmap \
      libcurl4 \
      wget && \
      apt-get install -y --reinstall overlay-scrollbar-gtk2 && \
      rm -rf /var/lib/apt/lists/*

# Install Metashape & Python 3 Module
Run cd /opt && wget https://s3-eu-west-1.amazonaws.com/download.agisoft.com/metashape-pro_2_1_1_amd64.tar.gz && \
	tar xvzf metashape-pro_2_1_1_amd64.tar.gz && \
	export PATH=$PATH:/opt/metashape-pro && \
        rm -rf *.tar.gz

RUN apt-get update -y && apt-get install -y python3-pip
RUN cd /opt && wget https://s3-eu-west-1.amazonaws.com/download.agisoft.com/Metashape-2.1.1-cp37.cp38.cp39.cp310.cp311-abi3-linux_x86_64.whl && \
        pip3 install Metashape-2.1.1-cp37.cp38.cp39.cp310.cp311-abi3-linux_x86_64.whl && \
	rm -rf *.whl

CMD chmod -R 755 /opt/

ENV PATH=$PATH:/opt/metashape-pro

CMD /opt/metashape-pro/metashape.sh

# Add licenses - do not save licenses in repository
COPY server.lic /opt/metashape-pro/server.lic
