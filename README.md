# Docker GPU machine for Machine Learning

Set up a docker image that can be moved from machine to machine depending on the use case.

## Interesting links

[Platform: Docker](https://forums.fast.ai/t/platform-docker-free-non-beginner/65908/21)

## GCP server

Actual commands run (project id is the default so we don't need to specify)

### Firewall

```
gcloud compute networks create fastai --subnet-mode=auto
gcloud compute firewall-rules create fastai-rules --network fastai --allow tcp:22,icmp --source-ranges=0.0.0.0/0
```

Note that since we run everything over Tailscale, port 22 is all we need (for the initial tailscale installation)

### Server

[Creating a Deep Learning VM Instance From the Command Line](https://cloud.google.com/ai-platform/deep-learning-vm/docs/cli)

Standard:
```
gcloud compute instances create compute \
        --zone=europe-west4-c \
        --image-family=pytorch-latest-gpu \
        --image-project=deeplearning-platform-release \
        --maintenance-policy=TERMINATE \
        --accelerator="type=nvidia-tesla-t4,count=1" \
        --machine-type=n1-highmem-4 \
        --boot-disk-size=200GB \
        --metadata="install-nvidia-driver=True" \
        --preemptible
```
Bigger: (`--accelerator="type=nvidia-tesla-p100,count=1" --machine-type=n1-highmem-8 --boot-disk-size=200GB`)
```
gcloud compute instances create compute \
        --zone=europe-west4-c \
        --image-family=pytorch-latest-gpu \
        --image-project=deeplearning-platform-release \
        --maintenance-policy=TERMINATE \
        --accelerator="type=nvidia-tesla-p100,count=1" \
        --machine-type=n1-highmem-8 \
        --boot-disk-size=200GB \
        --metadata="install-nvidia-driver=True" \
        --preemptible
```
No GPU: (`--image-family=pytorch-latest-cpu` no accelerator, no metadata)
```
gcloud compute instances create compute \
        --zone=europe-west4-c \
        --image-family=pytorch-latest-cpu \
        --image-project=deeplearning-platform-release \
        --maintenance-policy=TERMINATE \
        --machine-type=n1-highmem-4 \
        --boot-disk-size=200GB \
        --preemptible
```

To start: `gcloud compute instances start compute --zone=europe-west4-c`

To stop: `gcloud compute instances stop compute --zone=europe-west4-c`

To delete: `gcloud compute instances delete compute --zone=europe-west4-c --delete-disks=all`

## Install Tailscale

### First time setup (locally)

```
docker build -t tailscale:1.0.5 https://github.com/tailscale/tailscale.git#v1.0.5
docker run -d --name=tailscaled --hostname=compute \
        -v (pwd)/work/tailscale/conf:/var/lib/tailscale \
        -v /dev/net/tun:/dev/net/tun --privileged \
        tailscale:1.0.5 tailscaled
docker exec tailscaled tailscale up
docker exec tailscaled tailscale status
docker stop tailscaled
docker rm tailscaled

docker build -t fastai docker
```

### Remote setup

```
set -x REMOTE_IP 34.90.214.184
ssh-keygen -R $REMOTE_IP
rsync -avrz --exclude=.venv/ work $REMOTE_IP:
set -x DOCKER_HOST ssh://smurf@$REMOTE_IP
set -x REMOTE_HOME (ssh $REMOTE_IP pwd)

docker run -d --name=tailscaled --hostname=compute \
        -v $REMOTE_HOME/work/tailscale/conf:/var/lib/tailscale \
        -v /dev/net/tun:/dev/net/tun --privileged \
        docker.pkg.github.com/hsm/docker-gpu-machine/tailscale:1.0.5 tailscaled
```

GPU:
```
docker run -d --gpus all --name=fastai --network=container:tailscaled \
        --shm-size 24g --ulimit memlock=-1 \
        -v $REMOTE_HOME/work/projects:/home/smurf/projects \
        -v $REMOTE_HOME/.ssh/authorized_keys:/home/smurf/.ssh/authorized_keys \
        docker.pkg.github.com/hsm/docker-gpu-machine/fastai:latest
```

No GPU:
```
docker run -d --name=fastai  --network=container:tailscaled \
        --shm-size 24g --ulimit memlock=-1 \
        -v $REMOTE_HOME/work/projects:/home/smurf/projects \
        -v $REMOTE_HOME/.ssh/authorized_keys:/home/smurf/.ssh/authorized_keys \
        docker.pkg.github.com/hsm/docker-gpu-machine/fastai:latest
```

Local:
```
docker run -d --name=tailscaled --hostname=compute \
        -v (pwd)/work/tailscale/conf:/var/lib/tailscale \
        -v /dev/net/tun:/dev/net/tun --privileged \
        docker.pkg.github.com/hsm/docker-gpu-machine/tailscale:1.0.5 tailscaled

docker run -d --name=fastai --network=container:tailscaled \
        --shm-size 12g --ulimit memlock=-1 \
        -v (pwd)/work/projects:/home/smurf/projects \
        -v ~/.ssh/id_rsa.pub:/home/smurf/.ssh/authorized_keys:ro \
        docker.pkg.github.com/hsm/docker-gpu-machine/fastai:latest
```

Conda:
```
conda create -n fastai python=3.8
conda activate fastai
```

```
conda install -c fastai -c pytorch fastai
conda install jupyter notebook
jupyter notebook --ip=0.0.0.0 --no-browser
```
