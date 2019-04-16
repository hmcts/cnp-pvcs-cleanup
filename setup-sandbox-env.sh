#!/bin/sh 

#login DCD-CFT-Sandbox
az account set -s bf308a5c-0624-4334-8ff8-8dca9fd43783 && az aks get-credentials --resource-group cnp-aks-sandbox-rg --name cnp-aks-sandbox-cluster --subscription bf308a5c-0624-4334-8ff8-8dca9fd43783 --overwrite-existing && kubectl config use-context cnp-aks-sandbox-cluster && az acr helm repo add --subscription bf308a5c-0624-4334-8ff8-8dca9fd43783 -n hmcts
