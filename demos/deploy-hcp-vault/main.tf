provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_secret_id
}

# Create HVN
resource "hcp_hvn" "example" {
  hvn_id         =  var.hvn_id
  cloud_provider = "aws"
  region         = var.aws_region
  cidr_block     = "172.25.16.0/20"
}

# Create Vault Cluster
resource "hcp_vault_cluster" "vault_cluster" {
  hvn_id     = hcp_hvn.example.id
  cluster_id = var.vault_cluster_name
  public_endpoint = true
  tier = var.vault_tier
}

# Create Vault Admin Token
resource "hcp_vault_cluster_admin_token" "vault_admin_token" {
  cluster_id = hcp_vault_cluster.vault_cluster.cluster_id
}

