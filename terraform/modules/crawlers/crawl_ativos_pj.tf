# Obtém o nome do arquivo atual (sem o caminho e sem a extensão .tf)
locals {
  filename = replace(basename(abspath(path.module)), ".tf", "")
  crawler_name = replace(local.filename, "crawl_", "")
  # O nome do database agora é uma variável, mas tem um valor padrão baseado no nome do arquivo
  default_db_name = "${local.crawler_name}_database"
}

# Variáveis específicas para este crawler
variable "database_name" {
  description = "Nome do banco de dados Glue para este crawler"
  type        = string
  default     = ""  # Valor vazio indica que devemos usar o valor padrão
}

# Database do Glue para os metadados
resource "aws_glue_catalog_database" "db" {
  # Usa a variável se fornecida, caso contrário usa o valor padrão
  name = length(var.database_name) > 0 ? var.database_name : local.default_db_name
  description = "Banco de dados para ${local.crawler_name}"
}

# Crawler usando o nome do arquivo
module "crawler" {
  source = "../modules/glue_crawler"

  crawler_name   = local.crawler_name
  database_name  = aws_glue_catalog_database.db.name
  iam_role_arn   = var.glue_service_role_arn
  
  description    = "Crawler para dados de ${local.crawler_name} (execução manual)"
  
  # Lista de múltiplos alvos S3
  s3_targets     = [
    {
      path = "s3://${var.datalake_name}-prod/bronze/${local.crawler_name}/contas/",
      exclusions = ["**/_temporary/**", "**/.hive-staging/**"]
    },
    {
      path = "s3://${var.datalake_name}-prod/bronze/${local.crawler_name}/investimentos/"
    },
    {
      path = "s3://${var.datalake_name}-prod/bronze/${local.crawler_name}/imoveis/"
    }
  ]
  
  # Removido o schedule para permitir apenas execução manual
  # schedule = "cron(0 0 * * ? *)"
  
  delete_behavior = "DEPRECATE_IN_DATABASE"
  update_behavior = "UPDATE_IN_DATABASE"
  
  # Configuração JSON personalizada
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })
  
  tags = {
    Environment = "Production"
    DataDomain  = title(local.crawler_name)
    ExecutionMode = "Manual"
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