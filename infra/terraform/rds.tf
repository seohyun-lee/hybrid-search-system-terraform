# PostgreSQL (pgvector) — 선택. var.enable_rds = true 일 때만 생성.
resource "random_password" "db" {
  count   = var.enable_rds ? 1 : 0
  length  = 20
  special = false
}

resource "aws_db_subnet_group" "this" {
  count      = var.enable_rds ? 1 : 0
  name       = "${local.name}-db-subnets"
  subnet_ids = local.msk_subnet_ids
  tags       = { Name = "${local.name}-db-subnets" }
}

resource "aws_db_instance" "this" {
  count      = var.enable_rds ? 1 : 0
  identifier = "${local.name}-pg"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "calculation"
  username = var.db_username
  password = random_password.db[0].result

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  publicly_accessible    = false

  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${local.name}-pg" }
}
