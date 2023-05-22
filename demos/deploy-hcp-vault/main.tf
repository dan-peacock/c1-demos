provider "hcp" {
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
  hvn_id     = hcp_hvn.example.hvn_id
  cluster_id = var.vault_cluster_name
  public_endpoint = true
  tier = var.vault_tier
}

# Create Vault Admin Token aa
resource "hcp_vault_cluster_admin_token" "vault_admin_token" {
  cluster_id = hcp_vault_cluster.vault_cluster.cluster_id
}
