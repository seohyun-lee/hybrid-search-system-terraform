# VPC 도메인 생성에 필요한 서비스 연결 역할.
# 계정에 이미 존재하면 var.create_opensearch_slr = false (기본값)로 두세요.
resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_opensearch_slr ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_opensearch_domain" "this" {
  domain_name    = "${local.name}-os"
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count         = 1
    zone_awareness_enabled = false # 단일 노드(데모). 운영 시 멀티AZ 권장
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
  }

  # 단일 노드 → 단일 서브넷
  vpc_options {
    subnet_ids         = [local.app_subnet_id]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # VPC로 네트워크가 제한되므로 액세스 정책은 와일드카드 허용.
  # (Fine-grained access control은 데모 단순화를 위해 미사용)
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "es:*"
        Resource  = "arn:aws:es:${var.region}:${local.account_id}:domain/${local.name}-os/*"
      }
    ]
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}
