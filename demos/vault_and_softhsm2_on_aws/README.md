# Vault Enterprise and SoftHSM2

## VM on AWS

This repo contains some terraform code that:
- creates a VM on AWS (named "Vault ENT with SoftHSM" ) in the default VPC
- edits the default security group to allow all incoming traffic from your IP address
- installs some software on the VM using the user_data attribute of the aws_instance resource

Required variables:
- ssh_keyname: the name of the SSH in key in AWS to be used to connect to the instance
- vault_ent_license: the Vault Enterprise Plus license required to run Vault with a HSM 

## SW in the VM

the script installs and configures all the components as the ubuntu user.
- It installs and initialize SoftHSM2 on the first available slot
- it installs the latest vault enterprise + HSM from our official repos, and configures Vault to use the HSM
- in injects the required variables (VAULT_ADDR, VAULT_LICENSE) in the ~/.bashrc file

## how to run this

terraform:
- add the correct values in `terraform.auto.tfvars.example` and rename it `terraform.auto.tfvars`
- apply the terraform configuration  
    `terraform apply -auto-approve`

terraform will output the ssh connection string to be used to connect to the instance and the Vault UI address (not reachable yet)
```
connection_string = [
  "ssh -l ubuntu 34.243.255.212",
]
vault_ui = [
  "http://34.243.255.212:8200",
]
```

vault:  
ssh into the instance using the connection_string and then
- start the vault process  in background  
`nohup vault server -config=vault/config.hcl &`
- optional: see vault logs  
`tail [-f] nohup.out`
- init vault  
`vault operator init`

Vault is now running with the HSM unseal method.
Have fun

## troubleshooting
- read the userdata script output  
`tail -f /var/log/cloud-init-output.log`
- no env vars in shell
you logged in before the usedata script finished, logout and login


