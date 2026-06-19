output "host" {
  value = digitalocean_database_cluster.this.host
}

output "port" {
  value = digitalocean_database_cluster.this.port
}

output "user" {
  value = digitalocean_database_user.wordpress.name
}

output "name" {
  value = digitalocean_database_db.wordpress.name
}

output "password" {
  value     = digitalocean_database_user.wordpress.password
  sensitive = true
}

output "uri" {
  value     = digitalocean_database_cluster.this.private_uri
  sensitive = true
}
