#!/usr/bin/env sh

set -e

resource_group=$1
cluster_name=$2
vnet_name=$3

echo "Creating Azure Red Hat OpenShift cluster"
az aro create \
  --resource-group "$resource_group" \
  --name "$cluster_name" \
  --vnet "$vnet_name" \
  --vnet-resource-group "$resource_group" \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet

apiServer=$(az aro show -g "$resource_group" -n "$cluster_name" --query apiserverProfile.url -o tsv)
kubeUser=$(az aro list-credentials -g "$resource_group" -n "$cluster_name" | jq -r .kubeadminUsername)
kubePassword=$(az aro list-credentials -g "$resource_group" -n "$cluster_name" | jq -r .kubeadminPassword)

echo "Logging in"
oc login "$apiServer" -u "$kubeUser" -p "$kubePassword"
oc new-project consul