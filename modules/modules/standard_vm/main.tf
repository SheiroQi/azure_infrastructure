# 1. 创建网卡 (VM 的附属资源)
resource "azurerm_network_interface" "nic" {
  # [Naming Standard] 统一命名规范
  name                = "nic-${var.env}-${var.vm_name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id # 使用外部传入的子网
    private_ip_address_allocation = "Dynamic"
  }
}

# 2. 创建 VM 本体
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.env}-${var.vm_name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    # [Path Reference] 引用根目录的 Key 文件
    public_key = file("${path.root}/my_azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # [Logic: Tagging Policy] 自动打标
  # 用户只传了 env="Dev"，我们自动补全了 Dept 和 ManagedBy
  tags = {
    Environment = var.env
    Dept        = "IT"
    ManagedBy   = "Terraform-Module-Standard-VM"
  }
}

# 3. [Logic: Conditional Resource] 监控插件
# 机制: 这里的 count 是核心。如果 var.enable_monitoring 为 false，则 count=0，即不创建。
resource "azurerm_virtual_machine_extension" "monitor" {
  count                = var.enable_monitoring ? 1 : 0
  
  name                 = "AzureMonitorLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinux"
  type_handler_version = "1.0"
  # 简化的配置示例
  settings             = jsonencode({ "GADResourceId": azurerm_linux_virtual_machine.vm.id })
}

# 4. [Logic: Mandatory Policy] 杀毒软件
# 机制: 没有 count 判断，意味着无论什么环境，强制安装，不可关闭。
resource "azurerm_virtual_machine_extension" "antivirus" {
  name                 = "SecurityAgent"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Security"
  type                 = "IaaSAntimalware"
  type_handler_version = "1.3"
  settings             = jsonencode({ "AntimalwareEnabled": true })
}
