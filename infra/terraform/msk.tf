resource "aws_msk_cluster" "this" {
  cluster_name           = "${local.name}-msk"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = 2 # = private 서브넷 수

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = local.msk_subnet_ids
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.msk_volume_size
      }
    }
  }

  # 데모: 비인증 + plaintext 허용 (VPC 내부 SG로 접근 제한).
  # 운영 전환 시 IAM/SASL-SCRAM 인증으로 변경 권장.
  client_authentication {
    unauthenticated = true
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT" # 9092(plaintext) + 9094(TLS) 동시 지원
      in_cluster    = true
    }
  }

  tags = { Name = "${local.name}-msk" }
}
