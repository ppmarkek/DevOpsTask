variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type    = string
  default = "wp-dev"
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "db_size" {
  type    = string
  default = "db-s-1vcpu-1gb"
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_user" {
  type    = string
  default = "wordpress"
}

variable "registry_name" {
  type    = string
  default = "wp-devops"
}
