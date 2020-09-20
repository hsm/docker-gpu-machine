FROM nvidia/cuda:11.0-base-ubuntu20.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
&& apt-get install -y curl python3-venv fish fzf git sudo tmux vim openssh-server htop \
&& rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd \
&& sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
&& sed -i 's/AcceptEnv LANG LC_\*/#AcceptEnv LANG LC_*/g' /etc/ssh/sshd_config \
&& useradd --create-home --shell /usr/bin/fish --uid 1000 smurf \
&& echo 'smurf ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
&& echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf
COPY authorized_keys /home/smurf/.ssh/authorized_keys
RUN chown -R smurf:smurf ~smurf/.ssh

USER smurf
SHELL ["fish", "--command"]
ENV SHELL /usr/bin/fish
ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8
RUN curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish \
&& source ~/.config/fish/functions/fisher.fish \
&& fisher add jethrokuan/fzf
COPY *.fish /home/smurf/.config/fish/conf.d/

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -Lo ~/Miniconda3-latest-Linux-x86_64.sh \
&& bash ~/Miniconda3-latest-Linux-x86_64.sh -p ~/miniconda3 -b \
&& ~/miniconda3/bin/conda init fish \
&& source ~/.config/fish/config.fish \
&& conda update -y conda \
&& conda config --set auto_activate_base false \
&& rm ~/Miniconda3-latest-Linux-x86_64.sh

USER root
ENTRYPOINT ["/usr/sbin/sshd", "-D"]
