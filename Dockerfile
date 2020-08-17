ARG GO_VERSION=1.15
ARG BATS_VERSION=v1.2.0
ARG CRIU_VERSION=v3.14

FROM golang:${GO_VERSION}-buster
ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture armel \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture arm64 \
    && dpkg --add-architecture ppc64el \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        crossbuild-essential-arm64 \
        crossbuild-essential-armel \
        crossbuild-essential-armhf \
        crossbuild-essential-ppc64el \
        curl \
        gawk \
        iptables \
        jq \
        kmod \
        libaio-dev \
        libcap-dev \
        libnet-dev \
        libnl-3-dev \
        libprotobuf-c-dev \
        libprotobuf-dev \
        libseccomp-dev \
        libseccomp-dev:arm64 \
        libseccomp-dev:armel \
        libseccomp-dev:armhf \
        libseccomp-dev:ppc64el \
        libseccomp2 \
        pkg-config \
        protobuf-c-compiler \
        protobuf-compiler \
        python-minimal \
        sudo \
        uidmap \
    && apt-get clean \
    && rm -rf /var/cache/apt /var/lib/apt/lists/*;

# Add a dummy user for the rootless integration tests. While runC does
# not require an entry in /etc/passwd to operate, one of the tests uses
# `git clone` -- and `git clone` does not allow you to clone a
# repository if the current uid does not have an entry in /etc/passwd.
RUN useradd -u1000 -m -d/home/rootless -s/bin/bash rootless

# install bats
ARG BATS_VERSION
RUN cd /tmp \
    && git clone https://github.com/bats-core/bats-core.git \
    && cd bats-core \
    && git reset --hard "${BATS_VERSION}" \
    && ./install.sh /usr/local \
    && rm -rf /tmp/bats-core

# install criu
ARG CRIU_VERSION
RUN mkdir -p /usr/src/criu \
    && curl -fsSL https://github.com/checkpoint-restore/criu/archive/${CRIU_VERSION}.tar.gz | tar -C /usr/src/criu/ -xz --strip-components=1 \
    && cd /usr/src/criu \
    && echo 1 > .gitid \
    && make -j $(nproc) install-criu \
    && cd - \
    && rm -rf /usr/src/criu

COPY script/tmpmount /
WORKDIR /go/src/github.com/opencontainers/runc
ENTRYPOINT ["/tmpmount"]

ADD tests/integration/testdata/busybox.tar /busybox
ADD tests/integration/testdata/debian.tar /debian
