resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = jsonencode({
    displayName = "MD Website Error Monitoring"
    gridLayout = {
      columns = "2"
      widgets = flatten([
        for k, v in local.tenant_envs : [
          {
            title = "mdwebsite-${k} 500s Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.md-website-500s[k].id}\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_SUM"
                    }
                  }
                  unitOverride = "count"
                }
                plotType       = "LINE"
                legendTemplate = "500s Count"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Count"
                scale = "LINEAR"
              }
            }
          },

          {
            title = "mdwebsite-${k} Alert Status"
            alertChart = {
              name = google_monitoring_alert_policy.md-website[k].name
            }
          }
        ]
      ])
    }
  })
}
