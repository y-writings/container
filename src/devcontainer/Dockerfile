ARG HOME_DIR=/home/node

FROM debian:stable-slim AS base

ARG HOME_DIR

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    passwd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --no-confirm --init none \
    --extra-conf "experimental-features = nix-command flakes" \
    --extra-conf "sandbox = false" \
    --extra-conf "filter-syscalls = false" \
    --extra-conf "use-sqlite-wal = false"

ENV PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:$PATH

COPY devcontainer/flake.nix devcontainer/flake.lock /tmp/flake/
RUN nix profile install --profile /nix/var/nix/profiles/default /tmp/flake#devtools \
    && rm -rf /tmp/flake

RUN set -eux; \
    mkdir -p /usr/local/bin /usr/local/lib/docker/cli-plugins /usr/bin; \
    link() { \
        name="$1"; \
        dest="$2"; \
        target="$(command -v "$name" || true)"; \
        if [ -z "$target" ]; then \
            echo "missing required executable in PATH: $name" >&2; \
            exit 1; \
        fi; \
        ln -sf "$target" "$dest"; \
    }; \
    link supervisord /usr/bin/supervisord; \
    link socat /usr/bin/socat; \
    link zsh /bin/zsh; \
    link docker /usr/local/bin/docker; \
    link docker-compose /usr/local/lib/docker/cli-plugins/docker-compose; \
    link nvim /usr/local/bin/nvim; \
    link bash /bin/bash


ENV TZ='Asia/Tokyo'
ENV SHELL=/bin/zsh
ENV DEVCONTAINER=true

#
# 基盤ツール周りの設定
#
FROM base AS package-installer

ARG HOME_DIR

ENV NPM_CONFIG_PREFIX=${HOME_DIR}/.local/share/npm
ENV MISE_DATA_DIR=${HOME_DIR}/.local/share/mise
ENV PATH=$PATH:$NPM_CONFIG_PREFIX/bin:${MISE_DATA_DIR}/bin:${MISE_DATA_DIR}/shims:${HOME_DIR}/workspace/bin

RUN mkdir -p ${NPM_CONFIG_PREFIX} \
    && mkdir -p ${MISE_DATA_DIR}
RUN mkdir -p ${MISE_DATA_DIR}/bin \
    && ln -sf "$(command -v mise)" "${MISE_DATA_DIR}/bin/mise"

#
# コンテナで使用する個別インストーラ
#
FROM package-installer AS setup-tools

ARG TARGETARCH

ARG HOME_DIR

RUN set -eux; \
    groupadd -g 1000 node; \
    useradd -m -d "${HOME_DIR}" -u 1000 -g 1000 -s /bin/sh node

RUN mkdir -p ${HOME_DIR}/workspace \
    ${HOME_DIR}/.config/gcloud \
    ${HOME_DIR}/.config/nvim \
    ${HOME_DIR}/.config/opencode \
    ${HOME_DIR}/.local/share/opencode \
    /commandHistory \
    && chown -R node:node ${HOME_DIR} /commandHistory

RUN chsh -s /bin/zsh node

USER node

RUN mise use -g node@lts uv@latest go@latest python@latest bun@latest \
    && node --version && npm --version \
    && npm install -g \
    pnpm@10.15.0

RUN bunx oh-my-opencode install --no-tui --claude=no --openai=yes --gemini=no --copilot=no
RUN bunx oh-my-opencode-slim install --no-tui --kimi=no --openai=yes --anthropic=no --copilot=no --zai-plan=no --antigravity=no --chutes=no --balanced-spend=no --tmux=no

#
# 最終イメージ
#
FROM setup-tools AS final

USER root

COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
COPY scripts/devcontainer-init.sh /usr/local/bin/devcontainer-init.sh
RUN chmod 0755 /usr/local/bin/devcontainer-init.sh

ENTRYPOINT ["/usr/local/bin/devcontainer-init.sh"]
