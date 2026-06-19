output "kubernetes_cluster_name" {
  value = module.doks.cluster_name
}

output "kubernetes_cluster_id" {
  value = module.doks.cluster_id
}

output "database_host" {
  value     = module.database.host
  sensitive = true
}

output "database_port" {
  value = module.database.port
}

output "database_user" {
  value = module.database.user
}

output "database_name" {
  value = module.database.name
}

output "database_password" {
  value     = module.database.password
  sensitive = true
}
