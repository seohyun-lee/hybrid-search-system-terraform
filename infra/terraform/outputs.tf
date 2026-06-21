output "app_public_ip" {
  description = "앱 서버 EIP"
  value       = aws_eip.app.public_ip
}

output "streamlit_url" {
  description = "Streamlit FE 접속 URL (앱 기동 후)"
  value       = "http://${aws_eip.app.public_ip}:8501"
}

output "fastapi_url" {
  description = "FastAPI(Query Coordinator) URL"
  value       = "http://${aws_eip.app.public_ip}:8000"
}

output "ssm_connect" {
  description = "키 없이 접속"
  value       = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.region}"
}

output "opensearch_endpoint" {
  description = "OpenSearch VPC 엔드포인트 (앱 서버 내부에서만 접근 가능)"
  value       = "https://${aws_opensearch_domain.this.endpoint}"
}

output "opensearch_dashboards" {
  value = "https://${aws_opensearch_domain.this.endpoint}/_dashboards"
}

output "kafka_bootstrap_brokers_plaintext" {
  description = "Kafka bootstrap (plaintext, 9092)"
  value       = aws_msk_cluster.this.bootstrap_brokers
}

output "kafka_bootstrap_brokers_tls" {
  description = "Kafka bootstrap (TLS, 9094)"
  value       = aws_msk_cluster.this.bootstrap_brokers_tls
}

output "s3_media_bucket" {
  value = aws_s3_bucket.media.bucket
}

output "rds_endpoint" {
  description = "RDS PostgreSQL 엔드포인트 (enable_rds=true 일 때)"
  value       = var.enable_rds ? aws_db_instance.this[0].endpoint : "(disabled)"
}

output "rds_password" {
  description = "RDS 비밀번호 (enable_rds=true 일 때). terraform output -raw rds_password 로 확인"
  value       = var.enable_rds ? random_password.db[0].result : "(disabled)"
  sensitive   = true
}
