variable "project" {
  description = "리소스 이름 접두사. 소문자/하이픈만 (OpenSearch 도메인명 제약)"
  type        = string
  default     = "calculation"
}

variable "owner" {
  description = "태그용 소유자"
  type        = string
  default     = "calculation-team"
}

variable "region" {
  description = "배포 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  description = "재사용할 VPC ID. 빈 문자열이면 기본(Default) VPC 사용 (계정 VPC 한도 회피)"
  type        = string
  default     = ""
}

variable "allowed_cidrs" {
  description = "FE(8501)/BE(8000)/SSH(22) 접근 허용 CIDR. 보안을 위해 본인 IP(예: 1.2.3.4/32)로 제한 권장"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---- EC2 (FE Streamlit + BE FastAPI + Worker) ----
variable "ec2_instance_type" {
  description = "앱 서버 인스턴스 타입"
  type        = string
  default     = "t3.large" # 임베딩 모델 로딩 고려. 비용 절감 시 t3.medium
}

variable "key_name" {
  description = "SSH 키페어 이름. SSM Session Manager만 쓸 경우 빈 문자열"
  type        = string
  default     = ""
}

# ---- OpenSearch ----
variable "opensearch_engine_version" {
  type    = string
  default = "OpenSearch_2.13"
}

variable "opensearch_instance_type" {
  type    = string
  default = "t3.small.search"
}

variable "create_opensearch_slr" {
  description = "OpenSearch 서비스 연결 역할(SLR) 생성 여부. 계정에 이미 있으면 false"
  type        = bool
  default     = false
}

# ---- MSK (Managed Kafka) ----
variable "kafka_version" {
  type    = string
  default = "3.6.0"
}

variable "msk_instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "msk_volume_size" {
  description = "브로커당 EBS 스토리지(GB)"
  type        = number
  default     = 20
}

# ---- RDS PostgreSQL (선택) ----
variable "enable_rds" {
  description = "PostgreSQL(pgvector) 생성 여부. 노트상 '필요한지 확인' 항목 → 기본 off"
  type        = bool
  default     = false
}

variable "db_username" {
  type    = string
  default = "msadmin"
}
