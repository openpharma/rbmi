
FROM rocker/r-ver:latest

ARG BUILD_ENV="public"

# If any certificates are put into misc/docker/certs then install them
# into the container (intended only for local use within corporate network)
COPY misc/docker/certs /tmp/certs
RUN  BUILD_ENV=${BUILD_ENV} /tmp/certs/install_certs.sh

ENV REQD_PKGS="\
    libicu-dev \
    g++ \
    gcc \
    gfortran \
    gsfonts \
    zlib1g-dev \
    make \
    libblas-dev \
    libssl-dev \
    pandoc \
    libxml2-dev \
    libcurl4-openssl-dev \
    git \
    vim \
    curl \
    libgit2-dev \
    libv8-dev \
    libsodium-dev \
    libgsl-dev \
    libpng-dev \
    libfontconfig1-dev \
    libopenblas-dev \
    liblapack-dev \
    libgmp3-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libtiff5-dev \
    wget \
    gdebi-core \
    cargo \
    qpdf \
    devscripts \
    cmake \
    libpq-dev \
    dnsutils \
    tidy \
    "

RUN apt-get update -y --fix-missing && \
    apt-get upgrade -y && \
    apt-get install -y $REQD_PKGS

ADD misc/docker/install_packages.R /
ADD DESCRIPTION /

RUN Rscript  /install_packages.R



ENV TINYTEX_DIR=/opt
ENV TINYTEX_INSTALLER=TinyTeX
RUN wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh
RUN mv /opt/.TinyTeX /opt/TinyTeX

ENV PATH="/opt/TinyTeX/bin/x86_64-linux:${PATH}"

