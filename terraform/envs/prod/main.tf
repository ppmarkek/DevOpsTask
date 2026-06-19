terraform {
  required_version = ">= 1.5"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# The DigitalOcean Container Registry is account-wide and is provisioned once
# via terraform/envs/dev. Prod consumes the same registry, so it is not declared here.

module "doks" {
  source = "../../modules/doks"

  cluster_name = var.cluster_name
  region       = var.region
  node_size    = var.node_size
  node_count   = var.node_count
}

module "database" {
  source = "../../modules/database"

  cluster_name = "${var.cluster_name}-db"
  region       = var.region
  db_size      = var.db_size
  db_name      = var.db_name
  db_user      = var.db_user
}
