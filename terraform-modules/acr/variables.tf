variable "name" {
  type        = string
  description = "ACR name. Must be globally unique, alphanumeric, 5-50 chars."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic" # POC sizing; Premium adds private endpoints + geo-replication for prod
}

variable "tags" {
  type    = map(string)
  default = {}
}
