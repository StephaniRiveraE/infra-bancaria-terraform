resource "aws_dynamodb_table" "switch_directorio" {
  name         = "switch-directorio-instituciones"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "institucion_id"

  attribute {
    name = "institucion_id"
    type = "S" 
  }

  tags = merge(var.common_tags, {
    Domain  = "Switch"
    Service = "Directorio"
    Layer   = "Persistence-NoSQL"
  })
}

resource "aws_dynamodb_table" "sucursales_tables" {
  for_each     = toset(var.bancos)
  
  name         = "${each.key}-sucursales-geo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sucursal_id"

  attribute {
    name = "sucursal_id"
    type = "S"
  }

  tags = merge(var.common_tags, {
    Domain  = title(each.key)
    Service = "Geografia"
    Layer   = "Persistence-NoSQL"
  })
}