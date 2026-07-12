output "ssm_parameter_name" {
  description = "SSM parameter path that stores this pre-auth key."
  value       = aws_ssm_parameter.this.name
}
