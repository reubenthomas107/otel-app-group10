resource "aws_cloudwatch_metric_alarm" "avg_frontendproxy_pod_cpu_utilization" {
  alarm_name          = "frontend-proxy-pod-cpu-utilization-alarm"
  alarm_description   = "Alarm when average pod CPU utilization exceeds 50% for the last 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 50 #80
  evaluation_periods  = 1
  period = 300
  metric_name = "pod_cpu_utilization"
  namespace = "ContainerInsights"
  statistic = "Average"
  
  dimensions = {
    ClusterName = "otel-app-cluster"
    Namespace  = "helm-otel-demo"
    PodName    = "frontend-proxy"
  }
  alarm_actions = [aws_sns_topic.otel_app_sns.arn]
}


resource "aws_cloudwatch_metric_alarm" "avg_loadgen_pod_cpu_utilization" {
  alarm_name          = "load-generator-pod-cpu-utilization-alarm"
  alarm_description   = "Alarm when average pod CPU utilization exceeds 80% for the last 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70 #80
  evaluation_periods  = 1
  period = 300
  metric_name = "pod_cpu_utilization"
  namespace = "ContainerInsights"
  statistic = "Average"
  
  dimensions = {
    ClusterName = "otel-app-cluster"
    Namespace  = "helm-otel-demo"
    PodName    = "load-generator"
  }
  alarm_actions = [aws_sns_topic.otel_app_sns.arn]
}

# Monitoring the number of restarts for the frontend-proxy pod
resource "aws_cloudwatch_metric_alarm" "frontend_proxy_pod_restarts" {
  alarm_name          = "frontend-proxy-pod-restart-alarm"
  alarm_description   = "Alarm when pod restarts more than 4 times in the last 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 4 
  evaluation_periods  = 1
  period = 300
  metric_name = "pod_number_of_container_restarts"
  namespace = "ContainerInsights"
  statistic = "Sum"
  
  dimensions = {
    ClusterName = "otel-app-cluster"
    Namespace  = "helm-otel-demo"
    PodName    = "frontend-proxy"
  }
  alarm_actions = [aws_sns_topic.otel_app_sns.arn]
}

# Monitoring the number of restarts for the entire namespace
resource "aws_cloudwatch_metric_alarm" "namespace_pod_restarts" {
  alarm_name          = "namespace-pod-restart-alarm"
  alarm_description   = "Alarm when pod restarts more than 4 times in the last 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 4 
  evaluation_periods  = 1
  
  metric_query {
    id          = "q1"
    label       = "pod-restarts-helm-otel-demo-namespace"
    expression = "SELECT SUM(pod_number_of_container_restarts) FROM SCHEMA(ContainerInsights, ClusterName,Namespace,PodName) WHERE ClusterName = 'otel-app-cluster' AND Namespace = 'helm-otel-demo'"
    return_data = true
    period = 300
  }
  alarm_actions = [aws_sns_topic.otel_app_sns.arn]
}
