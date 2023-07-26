# Vault auth: k8s and jwt

1) Open a dedicated pane and launch a local dev instance of Vault
```
vault server -dev -dev-root-token-id=root
```

2) Open another pane and start minikube
```
minikube start
```
then launch the following in the same pane
```
╰─$ kubectl proxy --port=9090
Starting to serve on 127.0.0.1:9090
```

3) open the third pane and:
- verify that `127.0.0.1:9090/openid/v1/jwks` is reachable
```
╰─$ curl 127.0.0.1:9090/openid/v1/jwks                                                                                                                                                                                                        1 ↵
{"keys":[{"use":"sig","kty":"RSA","kid":"123","alg":"RS256","n":"123","e":"123"}]}%
```
- set the required env variables
```
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="root"
```
- apply the configuration to the vault cluster
```
terraform init and apply
```


## Testing JWT
### generate tokens and login with two sa from the "default" k8s namespace:

fist user: terraform-sa-0
- generate token  
`kubectl create token terraform-sa-0`  

login via UI with
- method: JWT
- role: role-terraform-sa-0
- token: $TOKEN from first command

second user: terraform-sa-1
- generate token  
`kubectl create token terraform-sa-1`  

login via UI with
- method: JWT
- role: role-terraform-sa-1
- token: $TOKEN from first command

### verify user count
login with the root token and verify that you see [only one entity](http://localhost:8200/ui/vault/access/identity/entities), that has a "default" alias


### generate tokens and login with two sa from the "namespace-2" k8s namespace:
fist user: terraform-sa-ns2-0
- generate token  
`kubectl create token terraform-sa-ns2-0 -n namespace-2`  

login via UI with
- method: JWT
- role: role-terraform-sa-ns2-0
- token: $TOKEN from first command

second user: terraform-sa-ns2-1
- generate token  
`kubectl create token terraform-sa-ns2-1 -n namespace-2`  

login via UI with
- method: JWT
- role: role-terraform-sa-ns2-1
- token: $TOKEN from first command


### verify user count
login with the root token and verify that you see [only two entities](http://localhost:8200/ui/vault/access/identity/entities), and the new one has a "namespace-2" alias

## Testing Kubernetes

### login using the k8s method
fist user: terraform-sa-3
- generate token  
`TOKEN_SA3=$(kubectl create token terraform-sa-3)`  
- login using the CLI  
`vault write auth/kubernetes/login role=k8s-role-default jwt=${TOKEN_SA3}`

second user: terraform-sa-4
- generate token  
`TOKEN_SA4=$(kubectl create token terraform-sa-4)`  
- login using the CLI  
`vault write auth/kubernetes/login role=k8s-role-default jwt=${TOKEN_SA4}`

### verify user count
the entity page now shows two more entities, one for each service account who logged in