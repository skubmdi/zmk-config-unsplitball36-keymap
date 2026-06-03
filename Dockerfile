FROM zmkfirmware/zmk-build-arm:stable

WORKDIR /workspace
COPY config/west.yml /workspace/config/west.yml

RUN apt update && apt install -y yq
RUN west init -l /workspace/config && west update && west zephyr-export
