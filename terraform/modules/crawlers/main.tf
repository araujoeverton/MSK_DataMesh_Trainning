resource "aws_glue_crawler" "this" {
  name          = var.crawler_name
  role          = var.iam_role_arn
  database_name = var.database_name
  description   = var.description
  schedule      = var.schedule  # Este parâmetro deve ser opcional
  classifiers   = var.classifiers
  
  # Criar dinâmicamente múltiplos alvos S3
  dynamic "s3_target" {
    for_each = var.s3_targets
    content {
      path       = s3_target.value.path
      exclusions = lookup(s3_target.value, "exclusions", [])
    }
  }

  schema_change_policy {
    delete_behavior = var.delete_behavior
    update_behavior = var.update_behavior
  }

  configuration = var.configuration

  tags = merge(
    {
      Name = var.crawler_name
    },
    var.tags
  )
}