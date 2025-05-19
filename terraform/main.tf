terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configurando Provider
provider "aws" {
  region = var.region
}

################################
# VPC Configuration
################################

# Criando a VPC
resource "aws_vpc" "vpc_main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "VPC_Main"
    }
  )
}

# Criando subnets usando count
resource "aws_subnet" "subnets" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    var.tags,
    {
      Name = "VPC_Subnet_${count.index + 1}"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = merge(
    var.tags,
    {
      Name = "VPC_IGW"
    }
  )
}

# Route Table
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "Public_Route_Table"
    }
  )
}

# Associação da Route Table com as subnets
resource "aws_route_table_association" "rta_subnet" {
  count          = length(var.subnet_cidrs)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.rt_public.id
}

################################
# Data Lake Configuration - Medallion Architecture (Bronze, Silver, Gold)
################################

# Bucket para ambiente de produção
resource "aws_s3_bucket" "datalake_prod" {
  bucket = "${var.datalake_name}-prod"

  tags = merge(
    var.tags,
    {
      Name        = "DataLake-Prod"
      Environment = "production"
    }
  )
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

  tags = merge(
    var.tags,
    {
      Name        = "DataLake-Homolog"
      Environment = "homologation"
    }
  )
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

# Criando a estrutura de camadas Medallion para produção
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

# Criando a estrutura de camadas Medallion para homologação
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

################################
# Glue Jobs Configuration
################################

# Bucket para armazenar scripts do Glue
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.datalake_name}-glue-scripts"

  tags = merge(
    var.tags,
    {
      Name = "Glue-Scripts-Bucket"
    }
  )
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

# Chave KMS para criptografia
resource "aws_kms_key" "data_key" {
  description             = "KMS key para criptografia do Data Lake e MSK"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.datalake_name}-data-key"
    }
  )
}

resource "aws_kms_alias" "data_key_alias" {
  name          = "alias/${var.datalake_name}-data-key"
  target_key_id = aws_kms_key.data_key.key_id
}

# Security Group para Jobs do Glue
resource "aws_security_group" "glue_sg" {
  name        = "glue-jobs-sg"
  description = "Security group para jobs do Glue"
  vpc_id      = aws_vpc.vpc_main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "glue-jobs-sg"
    }
  )
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

  tags = var.tags
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

# Política para acesso do Glue ao MSK (Kafka)
resource "aws_iam_policy" "glue_kafka_access" {
  name        = "glue-kafka-access"
  description = "Permite que o Glue acesse o cluster MSK"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:ReadData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_kafka_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_kafka_access.arn
}

# Configuração de Segurança para Glue
resource "aws_glue_security_configuration" "glue_security_config" {
  name = "${var.datalake_name}-security-config"
  
  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn               = aws_kms_key.data_key.arn
    }
    
    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                  = aws_kms_key.data_key.arn
    }
    
    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = aws_kms_key.data_key.arn
    }
  }
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
    each.value.default_arguments,
    # Substituir argumentos específicos do MSK para o job Kafka para Bronze
    each.value.name == "kafka-to-bronze-financial-transactions" ? {
      "--kafka_bootstrap_servers" = module.kafka_msk.bootstrap_brokers_sasl_iam
      "--target_path" = "s3://${aws_s3_bucket.datalake_prod.bucket}/bronze/financial-transactions/"
      "--audit_table" = "s3://${aws_s3_bucket.datalake_prod.bucket}/bronze/audit/kafka-ingestion/"
    } : {}
  )

  glue_version      = each.value.glue_version
  max_retries       = each.value.max_retries
  timeout           = each.value.timeout
  worker_type       = each.value.worker_type
  number_of_workers = each.value.num_workers

  security_configuration = aws_glue_security_configuration.glue_security_config.name

  tags = merge(
    var.tags,
    {
      JobType = each.value.job_type
    }
  )

  # Dependência do upload do script para o S3
  depends_on = [aws_s3_object.glue_scripts]
}

################################
# MSK Kafka Configuration
################################

# Módulo MSK Kafka
module "kafka_msk" {
  source = "./modules/msk_kafka"
  
  cluster_name         = "${var.datalake_name}-kafka"
  vpc_id               = aws_vpc.vpc_main.id
  vpc_cidr_blocks      = [var.vpc_cidr]
  subnet_ids           = aws_subnet.subnets[*].id
  
  kafka_version        = var.kafka_version
  number_of_broker_nodes = var.msk_broker_nodes
  broker_instance_type = var.msk_broker_instance_type
  
  kms_key_arn          = aws_kms_key.data_key.arn
  
  client_broker_encryption = var.msk_client_broker_encryption
  sasl_iam_enabled      = var.msk_sasl_iam_enabled
  sasl_scram_enabled    = var.msk_sasl_scram_enabled
  
  enhanced_monitoring   = var.msk_enhanced_monitoring
  jmx_exporter_enabled  = var.msk_jmx_exporter_enabled
  node_exporter_enabled = var.msk_node_exporter_enabled
  
  log_retention_days    = var.msk_log_retention_days
  enable_audit_logging  = var.msk_enable_audit_logging
  
  glue_security_group_id = aws_security_group.glue_sg.id
  
  kafka_config_properties = var.msk_config_properties

  tags = var.tags
}