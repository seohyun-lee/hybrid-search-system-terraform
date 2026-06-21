"""
S3 이미지 업로드 헬퍼.

인증:
  - EC2(워커)에서 실행: 인스턴스 역할(calculation-ec2-role)이 s3:PutObject 권한을
    이미 갖고 있어 별도 키 불필요.
  - 로컬에서 실행: AWS_PROFILE 환경변수로 인증.  예) AWS_PROFILE=tf python s3_upload.py ...

버킷은 private + BucketOwnerEnforced(ACL 비활성)이므로 ACL 파라미터를 넘기지 않는다.

사용 예:
  # 단일 파일
  AWS_PROFILE=tf python scripts/s3_upload.py --bucket calculation-media-33f8d71f \
      ./cat.jpg --key images/cat.jpg --presign

  # 디렉토리 전체(이미지 확장자만) → images/ 프리픽스로 업로드
  AWS_PROFILE=tf python scripts/s3_upload.py --bucket calculation-media-33f8d71f \
      ./dataset --prefix images
"""
from __future__ import annotations

import argparse
import mimetypes
import os
from pathlib import Path

import boto3
from botocore.config import Config

REGION = os.environ.get("AWS_REGION", "ap-northeast-2")
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp"}

_s3 = boto3.client("s3", region_name=REGION, config=Config(retries={"max_attempts": 5}))


def upload_file(bucket: str, path: str | Path, key: str) -> str:
    """로컬 파일을 S3에 업로드하고 s3:// URI 반환."""
    path = Path(path)
    content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    _s3.upload_file(
        str(path),
        bucket,
        key,
        ExtraArgs={"ContentType": content_type},
    )
    print(f"uploaded  s3://{bucket}/{key}")
    return f"s3://{bucket}/{key}"


def upload_dir(bucket: str, directory: str | Path, prefix: str = "") -> list[str]:
    """디렉토리 내 이미지 파일을 모두 업로드. prefix/파일명 키로 저장."""
    directory = Path(directory)
    uris = []
    for p in sorted(directory.rglob("*")):
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS:
            rel = p.relative_to(directory).as_posix()
            key = f"{prefix.rstrip('/')}/{rel}" if prefix else rel
            uris.append(upload_file(bucket, p, key))
    print(f"\n총 {len(uris)}개 업로드 완료")
    return uris


def presigned_url(bucket: str, key: str, expires: int = 3600) -> str:
    """private 객체 조회용 presigned URL(기본 1시간) 생성."""
    url = _s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=expires,
    )
    return url


def main() -> None:
    ap = argparse.ArgumentParser(description="S3 이미지 업로드")
    ap.add_argument("source", help="업로드할 파일 또는 디렉토리 경로")
    ap.add_argument("--bucket", required=True, help="대상 S3 버킷")
    ap.add_argument("--key", help="단일 파일 업로드 시 S3 키 (미지정 시 파일명)")
    ap.add_argument("--prefix", default="", help="디렉토리 업로드 시 키 프리픽스")
    ap.add_argument("--presign", action="store_true", help="업로드 후 presigned URL 출력")
    args = ap.parse_args()

    src = Path(args.source)
    if src.is_dir():
        upload_dir(args.bucket, src, args.prefix)
    else:
        key = args.key or src.name
        upload_file(args.bucket, src, key)
        if args.presign:
            print("\npresigned URL (1h):")
            print(presigned_url(args.bucket, key))


if __name__ == "__main__":
    main()
