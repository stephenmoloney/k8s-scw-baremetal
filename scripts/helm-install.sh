#!/usr/bin/env bash

set -e

DESIRED_VERSION=$1

# Downloading helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && \
chmod +x get_helm.sh && \
./get_helm.sh

# Installing tiller and helm
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --skip-refresh --upgrade --service-account tiller

rm get_helm.sh
