output "service_monitor_names" {
  description = "List of created service monitor names"
  value       = keys(module.service_monitors)
}

output "task_monitor_names" {
  description = "List of created task monitor names"
  value       = keys(module.task_monitors)
}

output "cluster_monitor_names" {
  description = "List of created cluster monitor names"
  value       = keys(module.cluster_monitors)
}

output "apm_monitor_names" {
  description = "List of created APM monitor names"
  value       = keys(module.apm_monitors)
}

output "enabled_monitors" {
  description = "List of enabled monitor categories"
  value       = var.enabled_monitors
}

output "ecs_cluster_name" {
  description = "ECS cluster name being monitored"
  value       = var.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name being monitored"
  value       = var.ecs_service_name
}
