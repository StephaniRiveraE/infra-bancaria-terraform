terraform {
  backend "s3" {
    bucket         = "banca-ecosistema-tfstate-512be32e" 
    key            = "infra/terraform.tfstate"           
    region         = "us-east-2"                         
    dynamodb_table = "terraform-lock-table"              
    encrypt        = true                                
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "banca-ecosistema-tfstate-512be32e"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" 
  }
}
