FROM python:3.7-slim

ENV AWS_CLI_VERSION 1.18.5
ENV TERRAFORM_VERSION 0.15.5
ENV AWS_ACCESS_KEY_ID AWS_DEFAULT_REGION AWS_SECRET_ACCESS_KEY
ENV PATH=$PATH:/home/terraform/bin

RUN  apt-get update -y \
  && apt-get install bash git curl unzip make -y \
  && pip3 install "awscli==$AWS_CLI_VERSION" terrafile \
  && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
  && dpkg -i session-manager-plugin.deb \
  && git clone https://github.com/tfutils/tfenv.git ~/.tfenv \
  && mkdir -p ~/.local/bin/ \
  && . ~/.profile \
  && ~/.tfenv/bin/tfenv install $TERRAFORM_VERSION \
  && echo "$TERRAFORM_VERSION" >> ~/.tfenv/version \
  && apt autoremove -y \
  && groupadd terraform -g 1000 \
  && useradd terraform -u 1000 -g 1000 -s /bin/bash \
  && mv ~/.tfenv /home/terraform/ \
  && chown -R terraform. /home/terraform

USER terraform
