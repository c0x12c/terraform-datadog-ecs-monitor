locals {
  apm_service   = coalesce(var.apm_service_name, var.ecs_service_name)
  p99_threshold = coalesce(var.p99_latency_threshold, var.p95_latency_threshold * 3)

  # Display name for monitor titles
  service_display_name = var.ecs_service_name != "*" ? var.ecs_service_name : "All Services"

  ecs_filter     = "aws_account:${var.aws_account_id},environment:${var.environment},clustername:${var.ecs_cluster_name}"
  service_filter = var.ecs_service_name != "*" ? ",servicename:${var.ecs_service_name}" : ""

  # Standardized recovery threshold calculations
  recovery_ratio = var.recovery_threshold_ratio

  #==============================================================================
  # ECS Service Monitors
  #==============================================================================
  default_service_monitors = {
    service_cpu_high = {
      enabled        = true
      priority_level = 2
      title_tags     = "[High CPU] [ECS Service] [${local.service_display_name}]"
      title          = "CPU utilization is high"

      query_template = "avg($${timeframe}):avg:aws.ecs.service.cpuutilization{${local.ecs_filter}${local.service_filter}} by {servicename} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.cpu_critical_threshold
      threshold_critical_recovery = var.cpu_critical_threshold * local.recovery_ratio
      threshold_warning           = var.cpu_warning_threshold
      threshold_warning_recovery  = var.cpu_warning_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    service_cpu_critical = {
      enabled        = true
      priority_level = 1
      title_tags     = "[Critical CPU] [ECS Service] [${local.service_display_name}]"
      title          = "CPU utilization is critical"

      query_template = "avg($${timeframe}):avg:aws.ecs.service.cpuutilization{${local.ecs_filter}${local.service_filter}} by {servicename} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.cpu_critical_max_threshold
      threshold_critical_recovery = var.cpu_critical_max_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_critical
      renotify_occurrences        = 5
    }

    service_memory_high = {
      enabled        = true
      priority_level = 2
      title_tags     = "[High Memory] [ECS Service] [${local.service_display_name}]"
      title          = "Memory utilization is high"

      query_template = "avg($${timeframe}):avg:aws.ecs.service.memory_utilization{${local.ecs_filter}${local.service_filter}} by {servicename} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.memory_critical_threshold
      threshold_critical_recovery = var.memory_critical_threshold * local.recovery_ratio
      threshold_warning           = var.memory_warning_threshold
      threshold_warning_recovery  = var.memory_warning_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    service_memory_critical = {
      enabled        = true
      priority_level = 1
      title_tags     = "[Critical Memory] [ECS Service] [${local.service_display_name}]"
      title          = "Memory utilization is critical - OOM risk"

      query_template = "avg($${timeframe}):avg:aws.ecs.service.memory_utilization{${local.ecs_filter}${local.service_filter}} by {servicename} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.memory_critical_max_threshold
      threshold_critical_recovery = var.memory_critical_max_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_critical
      renotify_occurrences        = 5
    }

    service_running_tasks_low = {
      enabled        = true
      priority_level = 1
      title_tags     = "[Low Running Tasks] [ECS Service] [${local.service_display_name}]"
      title          = "Fewer running tasks than desired"

      query_template = "avg($${timeframe}):avg:aws.ecs.service.running{${local.ecs_filter}${local.service_filter}} by {servicename} - avg:aws.ecs.service.desired{${local.ecs_filter}${local.service_filter}} by {servicename} < $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = -1
      threshold_critical_recovery = 0
      renotify_interval           = var.renotify_interval_critical
      renotify_occurrences        = 5
      require_full_window         = false
    }

    service_task_count_zero = {
      enabled        = true
      priority_level = 1
      title_tags     = "[Service Down] [ECS Service] [${local.service_display_name}]"
      title          = "ECS Service has no running tasks"

      query_template = "max($${timeframe}):sum:aws.ecs.service.running{${local.ecs_filter}${local.service_filter}} by {servicename} <= $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical   = 0
      renotify_interval    = 10
      renotify_occurrences = 10
      require_full_window  = false
    }

    service_pending_tasks_stuck = {
      enabled        = true
      priority_level = 2
      title_tags     = "[Pending Tasks] [ECS Service] [${local.service_display_name}]"
      title          = "ECS Service has tasks stuck in pending state"

      query_template = "min($${timeframe}):sum:aws.ecs.service.pending{${local.ecs_filter}${local.service_filter}} by {servicename} > $${threshold_critical}"
      query_args = {
        timeframe = "last_10m"
      }

      threshold_critical   = 1
      renotify_interval    = var.renotify_interval_high
      renotify_occurrences = 3
    }
  }

  #==============================================================================
  # ECS Cluster Monitors (EC2 Launch Type only)
  #==============================================================================
  default_cluster_monitors = {
    cluster_cpu_reservation_high = {
      enabled        = var.launch_type == "EC2"
      priority_level = 2
      title_tags     = "[High CPU Reservation] [ECS Cluster] [${var.ecs_cluster_name}]"
      title          = "ECS Cluster CPU reservation is high - scaling needed"

      query_template = "avg($${timeframe}):avg:aws.ecs.cluster.cpureservation{${local.ecs_filter}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_10m"
      }

      threshold_critical          = var.cpu_critical_threshold
      threshold_critical_recovery = var.cpu_critical_threshold * local.recovery_ratio
      threshold_warning           = var.cpu_warning_threshold
      threshold_warning_recovery  = var.cpu_warning_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    cluster_memory_reservation_high = {
      enabled        = var.launch_type == "EC2"
      priority_level = 2
      title_tags     = "[High Memory Reservation] [ECS Cluster] [${var.ecs_cluster_name}]"
      title          = "ECS Cluster memory reservation is high - scaling needed"

      query_template = "avg($${timeframe}):avg:aws.ecs.cluster.memoryreservation{${local.ecs_filter}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_10m"
      }

      threshold_critical          = var.memory_critical_threshold
      threshold_critical_recovery = var.memory_critical_threshold * local.recovery_ratio
      threshold_warning           = var.memory_warning_threshold
      threshold_warning_recovery  = var.memory_warning_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    cluster_cpu_utilization_high = {
      enabled        = var.launch_type == "EC2"
      priority_level = 2
      title_tags     = "[High CPU Utilization] [ECS Cluster] [${var.ecs_cluster_name}]"
      title          = "ECS Cluster CPU utilization is high"

      query_template = "avg($${timeframe}):avg:aws.ecs.cluster.cpuutilization{${local.ecs_filter}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.cpu_critical_threshold
      threshold_critical_recovery = var.cpu_critical_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    cluster_memory_utilization_high = {
      enabled        = var.launch_type == "EC2"
      priority_level = 2
      title_tags     = "[High Memory Utilization] [ECS Cluster] [${var.ecs_cluster_name}]"
      title          = "ECS Cluster memory utilization is high"

      query_template = "avg($${timeframe}):avg:aws.ecs.cluster.memoryutilization{${local.ecs_filter}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
      }

      threshold_critical          = var.memory_critical_threshold
      threshold_critical_recovery = var.memory_critical_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }
  }

  #==============================================================================
  # APM/Trace Monitors
  #==============================================================================
  default_apm_monitors = {
    apm_p95_latency = {
      enabled        = true
      priority_level = 3
      title_tags     = "[High P95 Latency] [APM] [${local.apm_service}]"
      title          = "Service ${local.apm_service} P95 latency is high"

      query_template = "percentile($${timeframe}):p95:$${metric}{env:${var.environment},service:${local.apm_service}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
        metric    = var.apm_http_metric
      }

      threshold_critical          = var.p95_latency_threshold
      threshold_critical_recovery = var.p95_latency_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_medium
      renotify_occurrences        = 2
    }

    apm_p99_latency = {
      enabled        = true
      priority_level = 2
      title_tags     = "[High P99 Latency] [APM] [${local.apm_service}]"
      title          = "Service ${local.apm_service} P99 latency is high"

      query_template = "percentile($${timeframe}):p99:$${metric}{env:${var.environment},service:${local.apm_service}} > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
        metric    = var.apm_http_metric
      }

      threshold_critical          = local.p99_threshold
      threshold_critical_recovery = local.p99_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    apm_error_rate = {
      enabled        = true
      priority_level = 2
      title_tags     = "[High Error Rate] [APM] [${local.apm_service}]"
      title          = "Service ${local.apm_service} error rate is high"

      query_template = "sum($${timeframe}):(sum:$${metric}.errors{env:${var.environment},service:${local.apm_service}}.as_count() / sum:$${metric}.hits{env:${var.environment},service:${local.apm_service}}.as_count()) * 100 > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
        metric    = var.apm_http_metric
      }

      threshold_critical          = var.error_rate_threshold
      threshold_critical_recovery = var.error_rate_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
      require_full_window         = false
    }

    apm_error_count = {
      enabled        = true
      priority_level = 2
      title_tags     = "[Error Spike] [APM] [${local.apm_service}]"
      title          = "Service ${local.apm_service} error count is high"

      query_template = "sum($${timeframe}):sum:$${metric}.errors{env:${var.environment},service:${local.apm_service}}.as_count() > $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
        metric    = var.apm_http_metric
      }

      threshold_critical          = var.error_count_threshold
      threshold_critical_recovery = var.error_count_threshold * local.recovery_ratio
      renotify_interval           = var.renotify_interval_high
      renotify_occurrences        = 3
    }

    apm_throughput_drop = {
      enabled        = true
      priority_level = 3
      title_tags     = "[Throughput Drop] [APM] [${local.apm_service}]"
      title          = "Service ${local.apm_service} request throughput dropped significantly"

      query_template = "change(sum($${timeframe}),last_1h):sum:$${metric}.hits{env:${var.environment},service:${local.apm_service}}.as_count() < $${threshold_critical}"
      query_args = {
        timeframe = "last_5m"
        metric    = var.apm_http_metric
      }

      threshold_critical          = -50
      threshold_critical_recovery = -30
      renotify_interval           = var.renotify_interval_medium
      renotify_occurrences        = 2
      require_full_window         = false
    }
  }
}
