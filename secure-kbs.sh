#!/bin/bash

set -euo pipefail

set +x

node_ip="$(kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}")"

# create self signed certificate
openssl req -x509 -out kbs.crt -keyout kbs.key \
	-newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
	-nodes \
	-days 3650 \
	-subj '/CN=kbs.coco' \
	--addext "subjectAltName=IP:${node_ip}" \
	--addext "basicConstraints=CA:FALSE"

kubectl create secret tls kbs --cert=kbs.crt --key=kbs.key -n coco-tenant

config_map_name="$(kubectl get cm -n coco-tenant -o json | jq -r '.items[] | .metadata.name' | grep '^kbs-config')"
config_map="$(kubectl get cm -n coco-tenant "$config_map_name" -o jsonpath="{.data.kbs-config\.toml}")"
fixed_config_map="$(sed 's/insecure_http = true/private_key = "\/etc\/kbs\/https\/tls.key"\ncertificate = "\/etc\/kbs\/https\/tls.crt"/g' <<< "$config_map")"

# replace the config map with the fixed one
kubectl delete cm -n coco-tenant "$config_map_name"
kubectl create cm -n coco-tenant "$config_map_name" --from-literal=kbs-config.toml="$fixed_config_map"

# patch deploy/kbs to mount the secrets kbs-tls to /tls
kubectl patch deploy -n coco-tenant kbs --type='json' -p='[{"op": "add", "path": "/spec/template/spec/volumes/0", "value": {"name": "https", "secret": {"secretName" : "kbs"}}}, {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/0", "value": {"name": "https", "mountPath": "/etc/kbs/https"}}]'

svc_port="$(kubectl get svc kbs -n coco-tenant -o jsonpath="{.spec.ports[*].nodePort}")"
echo "https://${node_ip}:${svc_port}"
