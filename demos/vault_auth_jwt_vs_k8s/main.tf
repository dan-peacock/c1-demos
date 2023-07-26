# steps before running it
# 
terraform {
  required_providers {
    vault = {
      version = "3.15.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "vault" {
}

variable "kube_ip" {
  default = "127.0.0.1:9090"
}



/*
We're generating 4 service accounts in kubernetes, in the default namespace
these are named terraform-sa-0, terraform-sa-1, ... 
*/
resource "kubernetes_service_account" "sa-default" {
  count = 4
  metadata {
    name = "terraform-sa-${count.index}" 
  }
}

resource "kubernetes_namespace" "namespace-2" {
  metadata {
    annotations = {
      name = "namespace-2"
    }

    labels = {
      mylabel = "namespace-2"
    }

    name = "namespace-2"
  }
}

/*
We're generating 4 service accounts in kubernetes, in the "namespace-2" namespace
these are named terraform-sa-ns2-0, terraform-sa-ns2-1, ... 
*/

resource "kubernetes_service_account" "sa-ns2" {
  count = 4
  metadata {
    name = "terraform-sa-ns2-${count.index}"
    namespace = "namespace-2"
  }
}



/*
Setup the JWT auth method
*/
resource "vault_jwt_auth_backend" "jwt" {
    path = "jwt"
    jwks_url = "http://${var.kube_ip}/openid/v1/jwks"
}

/*
Generate the roles for the service accounts
*/
resource "vault_jwt_auth_backend_role" "role-ns-default" {
  count = length(kubernetes_service_account.sa-default)    
    
  backend         = vault_jwt_auth_backend.jwt.path
  role_name       = "role-${tolist(kubernetes_service_account.sa-default)[count.index].metadata[0].name}"
  role_type       = "jwt"
  token_policies  = ["default"] // TODO create custom policy for each one
  user_claim      = "/kubernetes.io/namespace"
  user_claim_json_pointer = true
  bound_audiences = ["https://kubernetes.default.svc.cluster.local","https://kubernetes.default.svc"]
  bound_claims = {
    "/kubernetes.io/serviceaccount/name": tolist(kubernetes_service_account.sa-default)[count.index].metadata[0].name
  }
}

resource "vault_jwt_auth_backend_role" "role-ns2" {
  count = length(kubernetes_service_account.sa-ns2)    
    
  backend         = vault_jwt_auth_backend.jwt.path
  role_name       = "role-${tolist(kubernetes_service_account.sa-ns2)[count.index].metadata[0].name}"
  role_type       = "jwt"
  token_policies  = ["default"] // TODO create custom policy for each one
  user_claim      = "/kubernetes.io/namespace"
  user_claim_json_pointer = true
  bound_audiences = ["https://kubernetes.default.svc.cluster.local","https://kubernetes.default.svc"]
  bound_claims = {
    "/kubernetes.io/serviceaccount/name": tolist(kubernetes_service_account.sa-ns2)[count.index].metadata[0].name
  }
}


/*
Setup of the k8s auth method
*/
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "http://${var.kube_ip}"
  kubernetes_ca_cert = file("~/.minikube/ca.crt")
  disable_iss_validation = "true"
}



resource "vault_kubernetes_auth_backend_role" "role-ns-default" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = tolist(kubernetes_service_account.sa-default[*].metadata[0].name)
  role_name                        = "k8s-role-default"
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 3600
  audience                         = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_kubernetes_auth_backend_role" "role-ns-2" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = tolist(kubernetes_service_account.sa-ns2[*].metadata[0].name)
  role_name                        = "k8s-role-namespace2"
  bound_service_account_namespaces = ["namespace-2"]
  token_ttl                        = 3600
  audience                         = "https://kubernetes.default.svc.cluster.local"
}


/**
output "name" {
  value = [for item in kubernetes_service_account.example: item.metadata[0].name]
}*/
