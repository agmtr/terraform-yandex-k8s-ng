variable "cluster_id" {
  type = string
}

variable "name" {
  type    = string
  default = null
}

variable "desc" {
  type    = string
  default = null
}

variable "resources" {
  type = object({
    platform_id   = optional(string, "standard-v3")
    cores         = optional(number, 2)
    memory        = optional(number, 2)
    core_fraction = optional(number, 100)
    preemptible   = optional(bool, false)
  })
  default = {}
}

variable "network" {
  type = object({
    subnets = map(object({
      id   = string
      zone = string
    }))
    public_ip          = optional(bool, false)
    security_group_ids = optional(list(string), [])
  })
}

variable "maintenance_policy" {
  type = object({
    auto_upgrade = optional(bool, true)
    auto_repair  = optional(bool, true)
    day          = optional(string)
    start_time   = optional(string)
    duration     = optional(string)
  })
  default = {}
}

variable "config" {
  type = object({
    version                = optional(string)
    container_runtime      = optional(string, "docker")
    allowed_unsafe_sysctls = optional(list(string))
  })
  default = {}
}

variable "cloud_config" {
  type = object({
    template_file = optional(string, "./templates/cloud-init.tftpl")
    user          = optional(string, "cloud-user")
    pub_key_file  = optional(string, "~/.ssh/id_rsa.pub")
  })
  default = {}
}

variable "node_labels" {
  type    = map(string)
  default = {}
}

variable "node_taints" {
  type    = list(string)
  default = []
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "deploy_policy" {
  type = object({
    max_expansion   = optional(number)
    max_unavailable = optional(number)
  })
  default = {}
}

variable "scale_policy" {
  type = object({
    fixed = optional(object({
      size = number
    }))
    auto = optional(object({
      initial = number
      min     = number
      max     = number
    }))
  })
  default = {
    fixed = {
      size = 1
    }
  }
}
