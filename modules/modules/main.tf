terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # [Backend] 状态锁配置
  # ⚠️ 动作: 请替换 storage_account_name 为 Step 2 生成的真实名字
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend-southeastasia"
    storage_account_name = "tfstate1766258752" 
    container_name       = "tfstate"
    key                  = "day48.terraform.tfstate"
  }
}

provider "azurerm" { features {} }

# 1. 引用 Layer 0 (读取现有资源组)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# ==========================================
# 2. 网络层 (Simple Mode - 直接定义)
# ==========================================
# 对于简单的资源，直接写在根目录比封装成模块更高效
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

# ==========================================
# 3. 计算层 (Module Call - 复杂封装)
# ==========================================
module "app_server" {
  source = "./modules/standard_vm"

  # [Data Lineage] 变量传导分析:
  
  # 1. 基础设施依赖 (Resource -> Module)
  # 将上面刚刚定义的 Subnet ID 传给模块
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.main_subnet.id 

  # 2. 根变量透传 (tfvars -> Root -> Module)
  # 直接将 dev.tfvars 里的值传进去
  location            = var.location
  env                 = var.env               # "Dev"
  vm_size             = var.vm_size           # "Standard_B1s"
  enable_monitoring   = var.enable_monitoring # false

  # 3. 根逻辑加工 (Logic Processing)
  # 在根目录决定具体名字后缀，模块只负责拼接
  vm_name_suffix      = "web-01" 
}

# 4. 最终输出
output "vm_ip" {
  value = module.app_server.private_ip
}
