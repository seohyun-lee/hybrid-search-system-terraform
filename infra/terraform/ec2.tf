# Amazon Linux 2023 최신 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.ec2_instance_type
  subnet_id                   = local.app_subnet_id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = true

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y python3.11 python3.11-pip git tmux jq

    # 기본 python3를 3.11로
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 || true
    python3.11 -m pip install --upgrade pip

    # 앱 작업 디렉토리
    install -d -o ec2-user -g ec2-user /opt/app

    # 인프라 엔드포인트는 `terraform output` 으로 확인 후 /opt/app/.env 에 채우세요.
    cat >/opt/app/.env.example <<'ENV'
    OPENSEARCH_HOST=
    OPENSEARCH_PORT=443
    KAFKA_BOOTSTRAP=
    S3_BUCKET=
    AWS_REGION=${var.region}
    ENV
    chown ec2-user:ec2-user /opt/app/.env.example
  EOF

  tags = { Name = "${local.name}-app" }
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"
  tags     = { Name = "${local.name}-eip" }
}
