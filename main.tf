terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  
  # [Backend] 状态存储 (Layer 0)
  # 这里已经填好了你刚才提供的 Storage Account Name
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend-southeastasia"
    storage_account_name = "tfstate1766304037"
    container_name       = "tfstate"
    key                  = "day48.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# =========================================================
# Part 1: Day 48 已有的正常资源 (Greenfield)
# =========================================================

# 1. 引用 Layer 0 (读取现有资源组)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 2. 网络层 (简单模式 - 直接定义)
resource "azurerm_virtual_network" "main_vnet" {
  name                = "vnet-simple-${var.env}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main_subnet" {
  name                 = "snet-default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. 计算层 (Module Call - 复杂封装)
module "app_server" {
  source = "./modules/standard_vm"

  # [传导 1] 基础设施依赖
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.main_subnet.id

  # [传导 2] 透传变量 (用户定)
  location            = var.location
  env                 = var.env
  vm_size             = var.vm_size
  enable_monitoring   = var.enable_monitoring

  # [传导 3] 隐形决策 (架构师定)
  vm_name_suffix      = "web-01"
}

output "vm_ip" {
  value = module.app_server.private_ip
}

# =========================================================
# Part 2: Day 49 新增 - 待导入的存量资源 (Brownfield)
# =========================================================
# 这些资源目前只在云上有，State 里没有。
# 我们写在这里作为“空壳”，准备用 terraform import 命令来“夺舍”它们。

# [Import Target 1] 手工创建的资源组
resource "azurerm_resource_group" "legacy_rg" {
  name     = "rg-manual-day49"
  location = "eastus"
}

# [Import Target 2] 手工创建的 VNet
resource "azurerm_virtual_network" "legacy_vnet" {
  name                = "vnet-legacy-prod"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.legacy_rg.name
  address_space       = ["192.168.0.0/16"]
  
  # 注意：这里故意没写 subnet，一会儿 plan 的时候观察提示
}
