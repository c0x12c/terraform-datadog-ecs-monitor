variable "aws_account_id" {
  description = "AWS account ID for metric filtering"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for filtering metrics"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for filtering metrics. Use '*' to monitor all services in the cluster"
  type        = string
  default     = "*"
}

variable "notification_slack_channel_prefix" {
  description = "Slack channel prefix for notifications (e.g., 'alerts-' results in 'alerts-prod')"
  type        = string
}

variable "tag_slack_channel" {
  description = "Whether to tag the Slack channel (@channel) in notifications"
  type        = bool
  default     = true
}

variable "launch_type" {
  description = "ECS launch type: EC2 or FARGATE. Cluster monitors are only enabled for EC2 launch type"
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "Launch type must be EC2 or FARGATE"
  }
}

variable "enabled_monitors" {
  description = "List of monitor categories to enable: service, cluster, apm"
  type        = list(string)
  default     = ["service", "apm"]

  validation {
    condition     = alltrue([for m in var.enabled_monitors : contains(["service", "cluster", "apm"], m)])
    error_message = "Valid monitor categories: service, cluster, apm"
  }
}

variable "override_default_monitors" {
  description = "Override default monitor configurations. Keys are monitor names, values are maps of attributes to override"
  type        = map(map(any))
  default     = {}
}

#==============================================================================
# APM Configuration
#==============================================================================

variable "apm_service_name" {
  description = "APM service name for trace metrics. Defaults to ecs_service_name if not specified"
  type        = string
  default     = null
}

variable "apm_http_metric" {
  description = "APM HTTP metric name for latency and error monitoring"
  type        = string
  default     = "trace.http.request"
}

#==============================================================================
# Threshold Configuration
#==============================================================================

variable "cpu_critical_threshold" {
  description = "CPU utilization critical threshold percentage"
  type        = number
  default     = 80
}

variable "cpu_warning_threshold" {
  description = "CPU utilization warning threshold percentage"
  type        = number
  default     = 70
}

variable "memory_critical_threshold" {
  description = "Memory utilization critical threshold percentage"
  type        = number
  default     = 80
}

variable "memory_warning_threshold" {
  description = "Memory utilization warning threshold percentage"
  type        = number
  default     = 70
}

variable "p95_latency_threshold" {
  description = "P95 latency critical threshold in seconds"
  type        = number
  default     = 1
}

variable "p99_latency_threshold" {
  description = "P99 latency critical threshold in seconds. Defaults to 3x p95_latency_threshold if not specified"
  type        = number
  default     = null
}

variable "error_rate_threshold" {
  description = "Error rate critical threshold percentage"
  type        = number
  default     = 1
}

variable "error_count_threshold" {
  description = "Error count critical threshold (absolute number)"
  type        = number
  default     = 10
}

#==============================================================================
# Renotification Configuration
#==============================================================================

variable "renotify_interval_critical" {
  description = "Renotification interval in minutes for critical (P1) monitors"
  type        = number
  default     = 15
}

variable "renotify_interval_high" {
  description = "Renotification interval in minutes for high priority (P2) monitors"
  type        = number
  default     = 30
}

variable "renotify_interval_medium" {
  description = "Renotification interval in minutes for medium priority (P3) monitors"
  type        = number
  default     = 60
}
