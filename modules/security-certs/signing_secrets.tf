
resource "aws_secretsmanager_secret" "bank_jws_public_keys" {
  for_each    = toset(var.bancos)
  name        = "apim/jws/${lower(each.key)}-public-key"
  description = "Llave publica RSA para validar firma JWS del banco ${each.key}"
  tags        = var.common_tags
}

resource "aws_secretsmanager_secret_version" "bank_jws_placeholder" {
  for_each      = toset(var.bancos)
  secret_id     = aws_secretsmanager_secret.bank_jws_public_keys[each.key].id
  secret_string = "PENDING_UPLOAD_PUBLIC_KEY_PEM"

  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "tls_private_key" "switch_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_secretsmanager_secret" "switch_private_key" {
  name        = "switch/signing/private-key"
  description = "Llave privada del Switch para firmar respuestas"
  tags        = var.common_tags
}

resource "aws_secretsmanager_secret_version" "switch_private_key_val" {
  secret_id     = aws_secretsmanager_secret.switch_private_key.id
  secret_string = tls_private_key.switch_signing_key.private_key_pem
}

resource "aws_secretsmanager_secret" "switch_public_key" {
  name        = "switch/signing/public-key"
  description = "Llave publica del Switch para que bancos validen firmas"
  tags        = var.common_tags
}

resource "aws_secretsmanager_secret_version" "switch_public_key_val" {
  secret_id     = aws_secretsmanager_secret.switch_public_key.id
  secret_string = tls_private_key.switch_signing_key.public_key_pem
}
