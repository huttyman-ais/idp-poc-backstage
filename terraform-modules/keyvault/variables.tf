variable "name" {
  type        = string
  description = "Key Vault name. Globally unique, alphanumeric/hyphens, max 24 chars."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
