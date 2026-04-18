FROM debian:stable-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
# Pinned source: update URL and SHA256 together.
ARG IROFFER_URL="https://iroffer.net/iroffer-dinoex-snap.tar.gz"
ARG IROFFER_SHA256="83ef3aa28de2d9f959f4b9ceff3a2a3cb84f11870b6d3fbf67ba2790061d8d19"
ENV BUILD_ARGS="-curl -geoip -upnp -ruby"

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	  ca-certificates \
	  curl \
	  gcc \
	  libc-dev \
	  libcurl4-openssl-dev \
	  libgeoip-dev \
	  libminiupnpc-dev \
	  libssl-dev \
	  make \
	  ruby \
	  ruby-dev \
	  tar; \
	rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/src
RUN set -eux; \
	curl -fsSL "${IROFFER_URL}" -o /tmp/iroffer-dinoex.tar.gz; \
	echo "${IROFFER_SHA256}  /tmp/iroffer-dinoex.tar.gz" | sha256sum -c -; \
	tar -xzf /tmp/iroffer-dinoex.tar.gz --strip-components=1 -C /tmp/src; \
	rm -f /tmp/iroffer-dinoex.tar.gz

RUN set -eux; \
	chmod +x ./Configure; \
	./Configure ${BUILD_ARGS}; \
	make -j"$(nproc)"

# Stage outputs: compiled binary + default web/config assets.
RUN set -eux; \
	mkdir -p /out/extras/www; \
	cp -p ./iroffer /out/iroffer; \
	cp -p ./*.html /out/extras/www/; \
	cp -rp ./htdocs /out/extras/www/; \
	cp -p ./sample.config /out/extras/sample.config; \
	cp -p ./sample.config /out/extras/sample.customized.config; \
	chmod 600 /out/extras/sample.config /out/extras/sample.customized.config; \
	sed -i -e "s|pidfile mybot.pid|pidfile /home/iroffer/config/mybot.pid|g" /out/extras/sample.customized.config; \
	sed -i -e "s|logfile mybot.log|logfile /home/iroffer/logs/mybot.log|g" /out/extras/sample.customized.config; \
	sed -i -e "s|statefile mybot.state|statefile /home/iroffer/config/mybot.state|g" /out/extras/sample.customized.config; \
	sed -i -e "s|xdcclistfile mybot.txt|xdcclistfile /home/iroffer/data/packlist.txt|g" /out/extras/sample.customized.config; \
	sed -i "/channel #dinoex -noannounce/s/^/#/" /out/extras/sample.customized.config; \
	sed -i "/# 2nd Network/,/^$/d" /out/extras/sample.customized.config; \
	sed -i "/# 3st Network/,/^$/d" /out/extras/sample.customized.config; \
	sed -i "/#no_status_log/s/#//g" /out/extras/sample.customized.config


FROM debian:stable-slim

ARG CONT_IMG_VER
ARG DEBIAN_FRONTEND=noninteractive
ARG IROFFER_USER_ID=999
ARG IROFFER_GROUP_ID=999

ENV CONT_IMG_VER=${CONT_IMG_VER:-v1.0}
ENV IROFFER_CONFIG_FILE_NAME=mybot.config

LABEL name="iroffer" \
	  version="${CONT_IMG_VER}" \
	  maintainer="Luis E Alvarado <admin@avnet.ws>" \
	  description="iroffer-dinoex XDCC bot with curl, GeoIP, Ruby, and UPnP support"

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	  ca-certificates \
	  libcurl4 \
	  libgeoip1 \
	  libminiupnpc18 \
	  ruby; \
	rm -rf /var/lib/apt/lists/*; \
	groupadd --gid "${IROFFER_GROUP_ID}" --system iroffer; \
	useradd \
	  --uid "${IROFFER_USER_ID}" \
	  --gid "${IROFFER_GROUP_ID}" \
	  --system \
	  --create-home \
	  --home-dir /home/iroffer \
	  --shell /usr/sbin/nologin \
	  iroffer; \
	mkdir -p /extras /home/iroffer/config /home/iroffer/data /home/iroffer/logs

COPY --from=builder /out/iroffer /iroffer
COPY --from=builder /out/extras /extras
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
	chmod 0755 /usr/local/bin/entrypoint.sh /iroffer; \
	ln -sf /usr/local/bin/entrypoint.sh /entrypoint.sh; \
	chown -R iroffer:iroffer /home/iroffer /extras

WORKDIR /home/iroffer
VOLUME ["/home/iroffer/config", "/home/iroffer/data"]
EXPOSE 30000-31000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
