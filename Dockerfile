FROM ubuntu:20.04
SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

# Timezone, Launguage設定
RUN apt update \
  && apt install -y --no-install-recommends \
     locales \
     software-properties-common tzdata \
  && locale-gen ja_JP ja_JP.UTF-8  \
  && update-locale LC_ALL=ja_JP.UTF-8 LANG=ja_JP.UTF-8 \
  && add-apt-repository universe

# keyboard setting
RUN apt install -y  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" keyboard-configuration

# basic pkgs
RUN apt-get update && apt-get install -y \
  build-essential  \
  iproute2 gnupg gnupg1 gnupg2 \
  libcanberra-gtk* \
  git wget curl \
  nano \
  xsel \
  usbutils \
  sudo

ARG UID
ARG GID
ARG USER_NAME
ARG GROUP_NAME
ARG PASSWORD
RUN groupadd -g ${GID} ${GROUP_NAME} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} -G sudo ${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 圧縮されたTeXLiveのインストーラーをダウンロードし，tmpディレクトリに保存
ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz /tmp/install-tl-unx.tar.gz
# インストーラーを解凍した際に配置するディレクトリを作成
RUN mkdir /tmp/install-tl-unx ;\
# ダウンロードしたinstall-tl-unx.tar.gzを解凍
    tar -xvf /tmp/install-tl-unx.tar.gz -C /tmp/install-tl-unx --strip-components=1 ;\
# TeXLiveのインストール用の設定ファイルを作成
    echo "selected_scheme scheme-basic" >> /tmp/install-tl-unx/texlive.profile ;\
# TeXLiveのインストール
    /tmp/install-tl-unx/install-tl -profile /tmp/install-tl-unx/texlive.profile ;\
# TeXLiveのバージョンを取得しインストールディレクトリを特定し，latestの名称でシンボリックリンクを作成
    TEX_LIVE_VERSION=$(/tmp/install-tl-unx/install-tl --version | tail -n +2 | awk '{print $5}'); \
    ln -s "/usr/local/texlive/${TEX_LIVE_VERSION}" /usr/local/texlive/latest
# インストールしたTeXLiveへパスを通す
ENV PATH="/usr/local/texlive/latest/bin/x86_64-linuxmusl:${PATH}"

# TeXLive Package Managerを使用して必要なパッケージをインストール
# texファイルの自動コンパイルパッケージをインストール
RUN sudo apt update ; sudo apt install -y texlive-full ;\
    sudo /usr/local/texlive/????/bin/*/tlmgr path add ;\
    sudo tlmgr update --self --all ;\
    sudo tlmgr install latexmk
# latexmkの設定ファイルをホストからイメージにコピー
COPY ./app/config/.latexmkrc /home/${USER_NAME}/.latexmkrc
# 2カラムの設定に必要なパッケージのインストール
RUN tlmgr install multirow ;\
# 日本語対応パッケージのインストール
    tlmgr install collection-langjapanese ;\
# フォントパッケージのインストール
    tlmgr install collection-fontsrecommended ;\
    tlmgr install collection-fontutils

# 不要なパッケージなどの削除(イメージの容量削減のため)
RUN apk del xz tar ;\
    rm -rf /var/cache/apk/* ;\
    rm -rf /tmp/*

COPY ./assets/texworks /home/${USER_NAME}/texworks

# alias
RUN echo "alias pbcopy='xsel --clipboard --input'" >> /home/${USER_NAME}/.bashrc
# ps1
RUN echo "PS1='\[\033[47;30m\]LaTeX\[\033[0m\]:\[\033[32m\]\u\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]$ '" >> /home/${USER_NAME}/.bashrc
# lang env
RUN echo "export LANG=C.UTF-8" >> /home/${USER_NAME}/.bashrc
RUN echo "export LANGUAGE=en_US:" >> /home/${USER_NAME}/.bashrc

# entrypoint
COPY assets/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh
WORKDIR /home/${USER_NAME}/texworks
ENTRYPOINT ["/tmp/setup.sh"]
