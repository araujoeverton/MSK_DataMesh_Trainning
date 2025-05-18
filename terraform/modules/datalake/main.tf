# Bucket para ambiente de produção
resource "aws_s3_bucket" "datalake_prod" {
  bucket = "${var.datalake_name}-prod"

  tags = {
    Name        = "DataLake-Prod"
    Environment = "production"
  }
}

# Configurações básicas do bucket de produção
resource "aws_s3_bucket_versioning" "datalake_prod_versioning" {
  bucket = aws_s3_bucket.datalake_prod.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake_prod_encryption" {
  bucket = aws_s3_bucket.datalake_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "datalake_prod_public_access" {
  bucket                  = aws_s3_bucket.datalake_prod.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket para ambiente de homologação
resource "aws_s3_bucket" "datalake_homolog" {
  bucket = "${var.datalake_name}-homolog"

  tags = {
    Name        = "DataLake-Homolog"
    Environment = "homologation"
  }
}

# Configurações básicas do bucket de homologação
resource "aws_s3_bucket_versioning" "datalake_homolog_versioning" {
  bucket = aws_s3_bucket.datalake_homolog.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake_homolog_encryption" {
  bucket = aws_s3_bucket.datalake_homolog.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "datalake_homolog_public_access" {
  bucket                  = aws_s3_bucket.datalake_homolog.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Criando a estrutura básica de diretórios no bucket de produção
resource "aws_s3_object" "datalake_prod_bronze" {
  bucket  = aws_s3_bucket.datalake_prod.id
  key     = "bronze/"
  content = ""
}

resource "aws_s3_object" "datalake_prod_silver" {
  bucket  = aws_s3_bucket.datalake_prod.id
  key     = "silver/"
  content = ""
}

resource "aws_s3_object" "datalake_prod_gold" {
  bucket  = aws_s3_bucket.datalake_prod.id
  key     = "gold/"
  content = ""
}

# Criando a estrutura básica de diretórios no bucket de homologação
resource "aws_s3_object" "datalake_homolog_bronze" {
  bucket  = aws_s3_bucket.datalake_homolog.id
  key     = "bronze/"
  content = ""
}

resource "aws_s3_object" "datalake_homolog_silver" {
  bucket  = aws_s3_bucket.datalake_homolog.id
  key     = "silver/"
  content = ""
}

resource "aws_s3_object" "datalake_homolog_gold" {
  bucket  = aws_s3_bucket.datalake_homolog.id
  key     = "gold/"
  content = ""
}