provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Provisioned_by = "terraform"
    }
  }
}