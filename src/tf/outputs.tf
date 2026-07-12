output "ssm_paths" {
  value = merge(
    module.headscale.ssm_paths,
    module.uptime_kuma.ssm_paths,
  )
}
