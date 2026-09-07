FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc-multilib \
    g++-multilib \
    7zip \
    lhasa \
    iat \
    rename \
    wget \
    unzip \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

CMD ["make"]
