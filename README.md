# KBS Initdata

Utilities for using CoCo KBS with Initdata

## Secure KBS

Assuming a KBS installation based on kustomize using the `NodePort` variant. This will create https key + cert, push them as secrets to kubernetes and patch the kbs deployment to use them.

```bash
./secure-kbs.sh
```

## Generate Initdata

Use the output from the previous command as kbs url

```bash
export KBS_URL=https://10.200.24.11:32333
export KBS_CERT="$(<./kbs.crt)"
export POLICY="$(<./policy.rego)"
cat <<EOF > init_data
algorithm = "sha256"
version = "0.1.0"

[data]
"aa.toml" = '''
[token_configs]
[token_configs.coco_as]
url = '${KBS_URL}'

[token_configs.kbs]
url = '${KBS_URL}'
cert = """
${KBS_CERT}
"""
'''

"cdh.toml"  = '''
socket = 'unix:///run/confidential-containers/cdh.sock'

[kbc]
name = 'cc_kbc'
url = '${KBS_URL}'
kbs_cert = """
${KBS_CERT}
"""
'''

"policy.rego" = '''
${POLICY}
'''
EOF
```

## Deploy with Initdata

```bash
export INITDATA="$(base64 -w0 init_data)"
yq '.spec.template.metadata.annotations."io.katacontainers.config.runtime.cc_init_data" = env(INITDATA)' < nginx-cc.yaml  | kubectl apply -f -
```

## Test

```bash
kubectl exec deploy/nginx-cc -- curl -s http://127.0.0.1:8006/aa/token\?token_type=kbs
```

