output "ssh_commands" {
  value = { for k, ip in azurerm_public_ip.ws : k => "ssh workshop@${ip.ip_address}" }
}
