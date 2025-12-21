# 将内部深处的私有 IP 暴露给外部
output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
