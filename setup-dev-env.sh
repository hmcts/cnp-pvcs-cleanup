#!/bin/sh 

#login DCD-CNP-DEV
az account set -s 1c4f0704-a29e-403d-b719-b90c34ef14c9 && az aks get-credentials --resource-group cnp-aks-rg --name cnp-aks-cluster --subscription 1c4f0704-a29e-403d-b719-b90c34ef14c9 --overwrite-existing && kubectl config use-context cnp-aks-cluster && az acr helm repo add --subscription 1c4f0704-a29e-403d-b719-b90c34ef14c9 -n hmcts
