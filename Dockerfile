FROM node:22-bookworm-slim AS build

WORKDIR /opt

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git \
  && rm -rf /var/lib/apt/lists/*

ARG GIT_PROXY_REF=bc8eedc2754ab0c91ec7259cf33375a95cb62c6a
RUN git clone https://github.com/finos/git-proxy.git /opt/git-proxy \
  && cd /opt/git-proxy \
  && git checkout ${GIT_PROXY_REF}

COPY patches/git-proxy-stateless-gitleaks.patch /opt/git-proxy-stateless-gitleaks.patch
RUN cd /opt/git-proxy \
  && git apply --ignore-space-change --ignore-whitespace /opt/git-proxy-stateless-gitleaks.patch

WORKDIR /opt/git-proxy
RUN npm install \
  && npm run build


FROM node:22-bookworm-slim AS run

WORKDIR /opt/git-proxy

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git \
  && rm -rf /var/lib/apt/lists/*

ARG GITLEAKS_VERSION=8.24.2
RUN curl -sSL -o /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
  && tar -xzf /tmp/gitleaks.tar.gz -C /tmp \
  && install /tmp/gitleaks /usr/local/bin/gitleaks \
  && rm -f /tmp/gitleaks /tmp/gitleaks.tar.gz

COPY --from=build /opt/git-proxy/package.json /opt/git-proxy/package-lock.json ./
RUN npm install --omit=dev --ignore-scripts

COPY --from=build /opt/git-proxy/dist ./dist
COPY config/proxy.config.json /opt/git-proxy/proxy.config.json

ENV CONFIG_FILE=/opt/git-proxy/proxy.config.json
ENV GIT_PROXY_SERVER_PORT=8000
ENV GIT_PROXY_HTTPS_SERVER_PORT=8443

EXPOSE 8000

CMD ["node", "dist/index.js", "--config", "/opt/git-proxy/proxy.config.json"]
