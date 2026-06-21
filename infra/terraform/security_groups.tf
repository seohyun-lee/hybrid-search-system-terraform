# 앱 서버(EC2): FE Streamlit + BE FastAPI + Worker
resource "aws_security_group" "app" {
  name        = "${local.name}-app-sg"
  description = "FE/BE/Worker EC2"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Streamlit FE"
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "FastAPI BE (Query Coordinator)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-app-sg" }
}

# OpenSearch: 앱 서버에서만 HTTPS 접근
resource "aws_security_group" "opensearch" {
  name        = "${local.name}-os-sg"
  description = "OpenSearch domain"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "HTTPS from app"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-os-sg" }
}

# MSK: 앱 서버에서만 Kafka 접근 (9092 plaintext, 9094 TLS)
resource "aws_security_group" "msk" {
  name        = "${local.name}-msk-sg"
  description = "MSK brokers"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "Kafka plaintext"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "Kafka TLS"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-msk-sg" }
}

# RDS: 앱 서버에서만 Postgres 접근 (선택)
resource "aws_security_group" "rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${local.name}-rds-sg"
  description = "RDS PostgreSQL"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "Postgres from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-rds-sg" }
}
