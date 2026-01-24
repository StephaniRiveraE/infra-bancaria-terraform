terraform {
  backend "s3" {
    bucket         = "banca-ecosistema-tfstate-512be32e" 
    key            = "infra/terraform.tfstate"           
    region         = "us-east-2"                         
    dynamodb_table = "terraform-lock-table"              
    encrypt        = true                                
  }
}

# NOTA: El bucket S3 y tabla DynamoDB ya existen en AWS
# No se gestionan aquí para evitar conflictos, solo se referencian en el backend config arriba
