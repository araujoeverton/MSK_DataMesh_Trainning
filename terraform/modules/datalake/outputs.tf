

output "datalake_prod_bucket" {
  description = "Nome do bucket de produção do data lake"
  value       = aws_s3_bucket.datalake_prod.bucket
}

output "datalake_homolog_bucket" {
  description = "Nome do bucket de homologação do data lake"
  value       = aws_s3_bucket.datalake_homolog.bucket
}