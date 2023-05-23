locals {
  default_labels = {
    terraform = "true"
    terraform_module = basename(abspath(path.root))
  }
}

# data "cloudinit_config" "main" {
#   gzip          = false
#   base64_encode = true

#   part {
#     content_type = "text/cloud-config"
#     content = templatefile(
#       "${path.module}/${var.cloud_config.template_file}",
#       {
#         user    = var.cloud_config.user,
#         pub_key = file(var.cloud_config.pub_key_file)
#       }
#     )
#   }
# }

resource "random_id" "main" {
  byte_length = 4
}

resource "yandex_kubernetes_node_group" "main" {
  name        = var.name != null ? "${var.name}-${random_id.main.hex}" : "k8s-ng-${random_id.main.hex}"
  description = var.desc
  cluster_id  = var.cluster_id
  version     = var.config.version
  instance_template {
    platform_id = var.resources.platform_id
    resources {
      cores         = var.resources.cores
      core_fraction = var.resources.core_fraction
      memory        = var.resources.memory
    }
    network_interface {
      nat = var.network.public_ip
      # subnet_ids         = var.nodes.subnet_ids
      subnet_ids         = [for subnet in var.network.subnets : subnet.id]
      security_group_ids = var.network.security_group_ids
    }
    container_runtime {
      type = var.config.container_runtime
    }
    metadata = {
      ssh-keys = "${var.cloud_config.user}:${file(var.cloud_config.pub_key_file)}"
      # user-data = data.cloudinit_config.main.rendered
    }
    scheduling_policy {
      preemptible = var.resources.preemptible
    }
  }

  scale_policy {
    dynamic "fixed_scale" {
      for_each = var.scale_policy.fixed != null ? [1] : []

      content {
        size = var.scale_policy.fixed.size
      }
    }
    dynamic "auto_scale" {
      for_each = var.scale_policy.fixed != null ? [] : [1]

      content {
        initial = var.scale_policy.auto.initial
        min     = var.scale_policy.auto.min
        max     = var.scale_policy.auto.max
      }
    }
  }
  allocation_policy {
    dynamic "location" {
      for_each = var.network.subnets
      content {
        zone = location.value.zone
      }
    }
  }
  maintenance_policy {
    auto_upgrade = var.maintenance_policy.auto_upgrade
    auto_repair  = var.maintenance_policy.auto_repair
    dynamic "maintenance_window" {
      for_each = var.maintenance_policy.start_time != null ? [1] : []
      content {
        day        = var.maintenance_policy.day
        start_time = var.maintenance_policy.start_time
        duration   = var.maintenance_policy.duration
      }
    }
  }
  node_labels            = var.node_labels
  node_taints            = var.node_taints
  allowed_unsafe_sysctls = var.config.allowed_unsafe_sysctls
  dynamic "deploy_policy" {
    for_each = var.deploy_policy.max_expansion != null || var.deploy_policy.max_unavailable != null ? [1] : []

    content {
      max_expansion   = var.deploy_policy.max_expansion
      max_unavailable = var.deploy_policy.max_unavailable
    }
  }
  labels = merge(local.default_labels, var.labels)

  lifecycle {
    precondition {
      condition     = var.scale_policy.auto == null || var.scale_policy.fixed == null
      error_message = "You must use only one of scale_policy.auto or scale_policy.fixed options"
    }
  }
}
