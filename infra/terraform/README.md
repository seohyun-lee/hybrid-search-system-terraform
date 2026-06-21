# Terraform — calculation-demo 인프라

콘텐츠(미디어) 하이브리드 검색 데모용 AWS 인프라. (프로젝트 식별자: `calculation`)

## 생성 리소스

| 리소스 | 용도 | 사양(기본) |
|---|---|---|
| VPC + 서브넷 | public 2 / private 2, IGW (NAT 없음) | 10.0.0.0/16 |
| EC2 + EIP | FE(Streamlit) + BE(FastAPI) + Worker | t3.large, AL2023 |
| MSK | 이벤트 스트리밍 (색인 트리거) | kafka.t3.small × 2, plaintext |
| OpenSearch | BM25 + kNN 하이브리드 색인 | t3.small.search × 1 (VPC) |
| S3 | 이미지 적재 + presigned URL | private |
| RDS PostgreSQL | (선택) pgvector | db.t3.micro, `enable_rds=true` |
| IAM | EC2 role(S3, SSM) | - |

> ⚠️ MSK + OpenSearch는 시간당 과금됩니다. 데모 종료 후 반드시 `terraform destroy`.

## 사용법

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars   # 값 수정 (allowed_cidrs 등)

export AWS_PROFILE=...        # 또는 AWS_ACCESS_KEY_ID/SECRET
terraform init
terraform plan
terraform apply

# 엔드포인트 확인
terraform output
```

접속:
```bash
# SSH 키 없이 접속
aws ssm start-session --target $(terraform output -raw app_public_ip ...) --region ap-northeast-2
# (또는 output의 ssm_connect 명령 그대로 사용)
```

정리:
```bash
terraform destroy
```

## 주의사항

- **OpenSearch SLR**: 계정에 OpenSearch 서비스 연결 역할이 없으면 첫 apply가 실패합니다. 그 경우 `create_opensearch_slr = true` 로 설정 후 재실행.
- **allowed_cidrs**: 기본 `0.0.0.0/0` (전체 개방). 데모라도 본인 IP `/32`로 제한 권장.
- **MSK 비인증/plaintext**: VPC 내부 SG로만 접근 제한. 외부 노출 금지. 운영 전환 시 IAM/SASL 인증으로 변경.
- **state**: 로컬 저장. 팀 공유 시 `versions.tf`의 S3 backend 주석 해제.

## 다음 단계 (앱 배포)

`terraform output`의 엔드포인트를 EC2의 `/opt/app/.env`에 채운 뒤 워커/API/FE를 기동합니다.
전체 아키텍처와 Kafka 토픽 / OpenSearch 인덱스 매핑은 프로젝트 루트 [README](../../README.md) 참고.
