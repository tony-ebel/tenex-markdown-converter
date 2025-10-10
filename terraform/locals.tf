locals {
  tenet_env_combinations = setproduct(var.tenents, var.environments)

  tenet_envs = {
    for pair in local.tenet_env_combinations : "${pair[0]}-${pair[1]}" => {
      value1 = pair[0]
      value2 = pair[1]
    }
  }
}
