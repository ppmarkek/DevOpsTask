resource "digitalocean_database_cluster" "this" {
  name       = var.cluster_name
  engine     = "mysql"
  version    = "8"
  size       = var.db_size
  region     = var.region
  node_count = 1
}

resource "digitalocean_database_db" "wordpress" {
  cluster_id = digitalocean_database_cluster.this.id
  name       = var.db_name
}

resource "digitalocean_database_user" "wordpress" {
  cluster_id = digitalocean_database_cluster.this.id
  name       = var.db_user
}
