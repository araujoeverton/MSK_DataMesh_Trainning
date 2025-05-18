# Obtém o nome do arquivo atual (sem o caminho e sem a extensão .tf)
locals {
  filename = replace(basename(abspath(path.module)), ".tf", "")
  crawler_name = replace(local.filename, "crawl_", "")
  default_db_name = "${local.crawler_name}_database"
}

# Variáveis específicas para este crawler
variable "database_name" {
  description = "Nome do banco de dados Glue para este crawler"
  type        = string
  default     = ""  # Deixe vazio para usar o nome padrão baseado no arquivo
}

# Database do Glue para os metadados
resource "aws_glue_catalog_database" "db" {
  name = length(var.database_name) > 0 ? var.database_name : local.default_db_name
  description = "Banco de dados para ${local.crawler_name}"
}

# Crawler usando o nome do arquivo
module "crawler" {
  source = "../modules/glue_crawler"

  crawler_name   = local.crawler_name
  database_name  = aws_glue_catalog_database.db.name
  iam_role_arn   = var.glue_service_role_arn
  
  description    = "Crawler para dados de ${local.crawler_name}"
  
  # Lista de múltiplos alvos S3 - PERSONALIZE ESTES CAMINHOS
  s3_targets     = [
    {
      path = "s3://${var.datalake_name}-prod/bronze/${local.crawler_name}/PASTA1/",
      exclusions = ["**/_temporary/**", "**/.hive-staging/**"]
    },
    {
      path = "s3://${var.datalake_name}-prod/bronze/${local.crawler_name}/PASTA2/"
    }
  ]
  
  tags = {
    Environment = "Production"
    DataDomain  = title(local.crawler_name)
  }
}

# Outputs específicos deste crawler
output "crawler_name" {
  description = "Nome do crawler"
  value       = module.crawler.crawler_name
}

output "database_name" {
  description = "Nome do banco de dados"
  value       = aws_glue_catalog_database.db.name
}