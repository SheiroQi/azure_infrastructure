# 1. 基础设施依赖 (由调用者传入)
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { 
  type        = string
  description = "VM 必须接入一个现有的子网"
}

# 2. 业务参数 (强制校验)
variable "env" {
  type        = string
  description = "部署环境，用于标签策略"
  # [Validation Logic] 只能是 Dev, QA, Prod 之一，防止乱填
  validation {
    condition     = contains(["Dev", "QA", "Prod"], var.env)
    error_message = "Err: Environment must be one of: Dev, QA, Prod."
  }
}

variable "vm_name_suffix" {
  description = "VM 名字后缀 (e.g. web-01)"
}

variable "vm_size" {
  description = "VM 硬件规格"
}

# 3. 功能开关 (抽象能力的体现)
variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "是否启用 Azure Monitor 插件? Dev 环境可关闭以省钱。"
}
