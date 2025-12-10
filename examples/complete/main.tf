module "ecs_monitors_fargate" {
  source = "../../"

  aws_account_id   = "123456789012"
  environment      = "prod"
  ecs_cluster_name = "my-fargate-cluster"
  ecs_service_name = "my-api-service"
  launch_type      = "FARGATE"

  notification_slack_channel_prefix = "alerts-"
  tag_slack_channel                 = true

  enabled_monitors = ["service", "task", "apm"]

  # APM configuration
  apm_service_name = "my-api-service"
  apm_http_metric  = "trace.http.request"

  # Custom thresholds
  cpu_critical_threshold    = 85
  cpu_warning_threshold     = 75
  memory_critical_threshold = 85
  memory_warning_threshold  = 75
  p95_latency_threshold     = 0.5
  error_rate_threshold      = 0.5
}

module "ecs_monitors_ec2" {
  source = "../../"

  aws_account_id   = "123456789012"
  environment      = "prod"
  ecs_cluster_name = "my-ec2-cluster"
  ecs_service_name = "*"
  launch_type      = "EC2"

  notification_slack_channel_prefix = "alerts-"
  tag_slack_channel                 = true

  enabled_monitors = ["service", "task", "cluster"]

  # Override specific monitors
  override_default_monitors = {
    service_cpu_high = {
      threshold_critical = 90
      renotify_interval  = 20
    }
    cluster_cpu_reservation_high = {
      threshold_critical = 85
      threshold_warning  = 75
    }
  }
}
