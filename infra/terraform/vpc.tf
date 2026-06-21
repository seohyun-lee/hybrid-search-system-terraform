# 계정 VPC 한도(5개)가 차 있어 새 VPC를 만들지 않고 기존 VPC를 재사용한다.
# var.vpc_id 가 비어 있으면 기본(Default) VPC 사용.
data "aws_vpc" "selected" {
  default = var.vpc_id == "" ? true : null
  id      = var.vpc_id == "" ? null : var.vpc_id
}

# AZ별 default 서브넷 (모두 public). MSK는 2개 AZ, OpenSearch/EC2는 1개 사용.
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
