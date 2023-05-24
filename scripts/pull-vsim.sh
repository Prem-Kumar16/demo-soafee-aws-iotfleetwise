#!/bin/bash

sudo chmod 666 /var/run/docker.sock

# Get ECR login credentials to pull image

aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/h2b3x9k9
docker pull public.ecr.aws/h2b3x9k9/vsim:latest
docker tag public.ecr.aws/h2b3x9k9/vsim:latest vsim:latest
pushd vsim
if [ -e /run/k3s/containerd/containerd.sock ]; then
docker save vsim:latest | sudo ctr -a /run/k3s/containerd/containerd.sock -n=k8s.io images import -
fi
popd
