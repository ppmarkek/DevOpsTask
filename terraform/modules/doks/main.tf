resource "digitalocean_kubernetes_cluster" "this" {
  name   = var.cluster_name
  region = var.region
  version = data.digitalocean_kubernetes_versions.latest.latest_version

  node_pool {
    name       = "default"
    size       = var.node_size
    node_count = var.node_count
  }
}

data "digitalocean_kubernetes_versions" "latest" {}
