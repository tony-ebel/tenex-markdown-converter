locals {
  tenant_env_combinations = setproduct(var.tenants, var.environments)

  tenant_envs = {
    for pair in local.tenant_env_combinations : "${pair[0]}-${pair[1]}" => {
      tenant = pair[0]
      env    = pair[1]
    }
  }

  cloud_run_settings = {
    stage = {
      tag           = "beta"
      cpu           = "1"
      mem           = "2Gi"
      cpu_idle      = true
      min_instances = 0
      max_instances = 3
    }
    prod = {
      tag           = "latest"
      cpu           = "2"
      mem           = "4Gi"
      cpu_idle      = true
      min_instances = 0
      max_instances = 5
    }
  }
}
