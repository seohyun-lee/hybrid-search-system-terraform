# calculation-demo

콘텐츠(미디어) 메타데이터를 **키워드 + 시맨틱**으로 검색하는 데모 시스템.
메타데이터(+이미지 description 기반 임베딩)를 색인하고, Query Coordinator가
**BM25(키워드)** 와 **kNN(시맨틱)** 을 하이브리드로 검색한다.

> 프로젝트/리소스 식별자는 `calculation` 으로 통일. (실제 검색 대상은 영상/이미지 콘텐츠)

## 아키텍처

```
                          ┌─────────────────────────── EC2 (public) ───────────────────────────┐
콘텐츠 생성 이벤트     ──▶│                                                                      │
   (기본 메타데이터)       │   Worker ──▶ 1차 색인 ──┐                                            │
        │                  │   (Kafka consumer)      │                                            │
        ▼                  │                         ▼                                            │
   ┌─────────┐  consume    │                   ┌──────────┐    검색질의   ┌──────────────────┐    │
   │  MSK    │────────────▶│   Worker ──▶ 2차 색인 │ OpenSearch│◀───────────│ Query Coordinator│◀──┼── Streamlit FE
   │ (Kafka) │             │   (부가데이터 업데이트:│ (BM25 +  │            │ (FastAPI)        │    │   (8501)
   └─────────┘             │    임베딩 + BM25 필드) │  kNN)    │  결과       │ - 질의 임베딩    │    │
        ▲                  │                   └──────────┘            │ - 캐싱           │    │
        │ produce          │                                          └──────────────────┘    │
   부가데이터 업데이트       │   이미지 원본: S3 (presigned URL)                                  │
                          └──────────────────────────────────────────────────────────────────┘
```

### 색인 파이프라인 (2-phase)
1. **생성 이벤트** → Kafka `media.created` → Worker가 **1차 색인**(기본 메타데이터)
2. **부가데이터 업데이트** → Kafka `media.enriched` → Worker가 **2차 색인**
   - `image description → text → embedding` 으로 kNN 벡터 필드 채움
   - 텍스트 필드(제목/설명/태그)는 BM25용으로 분석

### 검색 (Query Coordinator)
- 질의 임베딩 + 결과 캐싱
- OpenSearch에서 키워드(BM25) + 시맨틱(kNN) 하이브리드 검색

## 데이터셋
- [lmms-lab/flickr30k](https://huggingface.co/datasets/lmms-lab/flickr30k)에서
  비어있지 않은 항목 위주로 ~10K 샘플링하여 색인.

## 디렉토리
```
calculation-demo/
├── infra/terraform/   # AWS 인프라 (VPC, EC2, MSK, OpenSearch, S3, RDS옵션)
│   └── README.md       # 배포 방법
└── README.md
```
(앱 코드 `api/` `worker/` `fe/` 는 추후 추가)

## 역할 분담 (논의 기준)
- **애림**: AWS 인프라(Terraform), MSK/Kafka 이벤트
- **서현**: Worker(비동기 색인), OpenSearch 인덱스 매핑

## 인프라 배포
[infra/terraform/README.md](infra/terraform/README.md) 참고.

## 참고: OpenSearch 인덱스 매핑 (예시)
```json
PUT /media
{
  "settings": { "index.knn": true },
  "mappings": {
    "properties": {
      "title":       { "type": "text" },
      "description": { "type": "text" },
      "tags":        { "type": "text" },
      "channel":     { "type": "keyword" },
      "thumbnail_s3":{ "type": "keyword" },
      "embedding":   { "type": "knn_vector", "dimension": 768,
                       "method": { "name": "hnsw", "engine": "lucene", "space_type": "cosinesimil" } }
    }
  }
}
```

## Kafka 토픽
| 토픽 | 발행 시점 | Worker 동작 |
|---|---|---|
| `media.created` | 콘텐츠 생성 | 1차 색인 (메타데이터) |
| `media.enriched` | 부가데이터 준비 완료 | 2차 색인 (임베딩 + BM25) |
