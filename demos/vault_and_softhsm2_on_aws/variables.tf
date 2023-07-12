variable "ami" {
    default = "ami-0f56955469757e5aa"
    description = "the base image to be used, it defaults to ubuntu"  
}

variable "instance_type" {
    default = "t3.small"
    description = "the instance type to be used"
}

variable "ssh_keyname" {
    default = ""
    description = "the ssh keyname to be used"
}

variable "vault_ent_license" {
    description = "the Vault Enterprise license"
}