provider "aws" {
  # Your primary region
  region = "eu-central-1"
}

provider "aws" {
  # CloudFront configuration is allowed only in us-east-1 region
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "kubernetes" {
}
