locals {
  name = var.project

  # 재사용 VPC의 서브넷 (정렬해 결정적으로 선택)
  subnet_ids = sort(data.aws_subnets.selected.ids)

  # 단일 노드(EC2/OpenSearch)는 첫 서브넷, MSK는 서로 다른 AZ 2개
  app_subnet_id  = local.subnet_ids[0]
  msk_subnet_ids = slice(local.subnet_ids, 0, 2)

  account_id = data.aws_caller_identity.current.account_id
}
