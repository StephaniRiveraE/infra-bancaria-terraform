
resource "aws_iam_policy" "cicd_ecr" {
  name        = "CICD-ECR-Push"
  description = "Permite push de imágenes Docker a ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "arn:aws:ecr:us-east-2:*:repository/*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "cicd_eks" {
  name        = "CICD-EKS-Deploy"
  description = "Permite deploy a EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "cicd_s3" {
  name        = "CICD-S3-Deploy"
  description = "Permite deploy de frontends a S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::banca-ecosistema-*",
          "arn:aws:s3:::banca-ecosistema-*/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_user" "cicd_deployer" {
  name = "github-actions-deployer"
  path = "/cicd/"

  tags = merge(var.common_tags, {
    Name    = "github-actions-deployer"
    Purpose = "CI/CD para despliegue de microservicios"
  })
}

resource "aws_iam_user_policy_attachment" "cicd_ecr" {
  user       = aws_iam_user.cicd_deployer.name
  policy_arn = aws_iam_policy.cicd_ecr.arn
}

resource "aws_iam_user_policy_attachment" "cicd_eks" {
  user       = aws_iam_user.cicd_deployer.name
  policy_arn = aws_iam_policy.cicd_eks.arn
}

resource "aws_iam_user_policy_attachment" "cicd_s3" {
  user       = aws_iam_user.cicd_deployer.name
  policy_arn = aws_iam_policy.cicd_s3.arn
}

resource "aws_iam_access_key" "cicd_deployer" {
  user = aws_iam_user.cicd_deployer.name
}
resource "aws_secretsmanager_secret" "cicd_credentials" {
  name        = "github-actions-deployer-credentials"
  description = "Credenciales IAM para CI/CD de microservicios"

  tags = merge(var.common_tags, {
    Name = "cicd-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "cicd_credentials" {
  secret_id = aws_secretsmanager_secret.cicd_credentials.id
  secret_string = jsonencode({
    aws_access_key_id     = aws_iam_access_key.cicd_deployer.id
    aws_secret_access_key = aws_iam_access_key.cicd_deployer.secret
    user_name             = aws_iam_user.cicd_deployer.name
    usage                 = "Usar estos valores en GitHub Secrets de cada repo de microservicio"
  })
}

output "cicd_credentials_secret_arn" {
  description = "ARN del secreto con credenciales de CI/CD"
  value       = aws_secretsmanager_secret.cicd_credentials.arn
}
