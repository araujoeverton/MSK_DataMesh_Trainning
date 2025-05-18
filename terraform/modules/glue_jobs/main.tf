################################
# Glue Jobs Configuration
################################

# Bucket para armazenar scripts do Glue
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.datalake_name}-glue-scripts"

  tags = {
    Name = "Glue-Scripts-Bucket"
  }
}

resource "aws_s3_bucket_versioning" "glue_scripts_versioning" {
  bucket = aws_s3_bucket.glue_scripts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_scripts_encryption" {
  bucket = aws_s3_bucket.glue_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts_public_access" {
  bucket                  = aws_s3_bucket.glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Criar estrutura de pastas para scripts do Glue de forma dinâmica
resource "aws_s3_object" "glue_scripts_directories" {
  for_each = toset(var.glue_job_directories)
  
  bucket  = aws_s3_bucket.glue_scripts.id
  key     = "scripts/${each.value}/"
  content = ""
}

# Criar pasta para armazenamento temporário
resource "aws_s3_object" "glue_temp_folder" {
  bucket  = aws_s3_bucket.glue_scripts.id
  key     = "temp/"
  content = ""
}

# IAM Role para o AWS Glue
resource "aws_iam_role" "glue_service_role" {
  name = "glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "GlueServiceRole"
  }
}

# Anexar políticas necessárias para o Glue
resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Política personalizada para acesso aos buckets S3
resource "aws_iam_policy" "glue_s3_access" {
  name        = "glue-s3-access"
  description = "Permite que o Glue acesse buckets S3 específicos"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.datalake_prod.arn,
          "${aws_s3_bucket.datalake_prod.arn}/*",
          aws_s3_bucket.datalake_homolog.arn,
          "${aws_s3_bucket.datalake_homolog.arn}/*",
          aws_s3_bucket.glue_scripts.arn,
          "${aws_s3_bucket.glue_scripts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

################################
# Upload dos scripts do Glue para S3 a partir dos arquivos locais de forma dinâmica
################################

resource "aws_s3_object" "glue_scripts" {
  for_each = { for idx, job in var.glue_jobs : job.name => job }
  
  bucket = aws_s3_bucket.glue_scripts.id
  key    = "scripts/${each.value.directory}/${each.value.filename}"
  source = "${path.module}/glue_jobs/${each.value.directory}/${each.value.filename}"
  etag   = filemd5("${path.module}/glue_jobs/${each.value.directory}/${each.value.filename}")
  content_type = "text/x-python"
}

################################
# Criação de Glue Jobs a partir dos scripts locais de forma dinâmica
################################

resource "aws_glue_job" "glue_jobs" {
  for_each = { for idx, job in var.glue_jobs : job.name => job }
  
  name     = each.value.name
  role_arn = aws_iam_role.glue_service_role.arn
  
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/${each.value.directory}/${each.value.filename}"
    python_version  = "3"
  }

  # Mesclando os argumentos default padrão com os específicos do job
  default_arguments = merge(
    {
      "--TempDir" = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    },
    each.value.default_arguments
  )

  glue_version      = each.value.glue_version
  max_retries       = each.value.max_retries
  timeout           = each.value.timeout
  worker_type       = each.value.worker_type
  number_of_workers = each.value.num_workers

  tags = {
    JobType = each.value.job_type
  }

  # Dependência do upload do script para o S3
  depends_on = [aws_s3_object.glue_scripts]
}