resource "digitalocean_container_registry" "this" {
  name                   = var.name
  subscription_tier_slug = "starter"
}
