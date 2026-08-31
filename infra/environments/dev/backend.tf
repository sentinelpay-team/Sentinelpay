terraform {

  backend "s3" {

    bucket = "sentinelpay-terraform-state-3ed7fc7c"

    key = "environments/dev/terraform.tfstate"

    region = "eu-west-1"

    encrypt = true

    dynamodb_table = "sentinelpay-terraform-locks"
  }
}