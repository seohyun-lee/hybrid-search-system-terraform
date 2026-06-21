terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # 데모용: state 로컬 저장. 팀 공유가 필요하면 아래 backend를 활성화하세요.
  # backend "s3" {
  #   bucket = "<your-tfstate-bucket>"
  #   key    = "calculation-demo/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}
