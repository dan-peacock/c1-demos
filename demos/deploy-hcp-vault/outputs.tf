# Print the Public URL
output "vault_public_endpoint_url" {
    value = hcp_vault_cluster.vault_cluster.public_endpoint
}

# Print the Root Token
output "vault_admin_token" {
    value = hcp_vault_cluster_admin_token.vault_admin_token.token
}
