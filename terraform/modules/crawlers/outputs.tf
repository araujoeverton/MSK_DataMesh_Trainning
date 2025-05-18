output "crawler_name" {
  description = "Nome do crawler criado"
  value       = aws_glue_crawler.this.name
}

output "crawler_arn" {
  description = "ARN do crawler criado"
  value       = aws_glue_crawler.this.arn
}