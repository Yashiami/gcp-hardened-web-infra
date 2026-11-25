resource "google_monitoring_notification_channel" "email" {
  display_name = "Ops Email Alerts"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_uptime_check_config" "web_health" {
  display_name = "Web App /health Uptime Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path           = "/health"
    port           = 80
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "google_logging_metric" "nginx_5xx" {
  name        = "nginx_http_5xx_count"
  description = "Counts HTTP 5xx responses logged by Nginx"
  filter      = "logName=\"projects/${var.project_id}/logs/nginx_access\" AND httpRequest.status>=500"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "nginx_5xx_spike" {
  display_name = "Nginx HTTP 5xx Spike"
  combiner     = "OR"

  conditions {
    display_name = "HTTP 5xx count > 3 in 1 minute"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.nginx_5xx.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
