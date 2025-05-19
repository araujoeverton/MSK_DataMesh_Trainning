output "msk_cluster_arn" {
  description = "ARN do cluster MSK"
  value       = aws_msk_cluster.this.arn
}

output "msk_cluster_name" {
  description = "Nome do cluster MSK"
  value       = aws_msk_cluster.this.cluster_name
}

output "bootstrap_brokers" {
  description = "Lista de bootstrap brokers para conexão plaintext"
  value       = aws_msk_cluster.this.bootstrap_brokers
}

output "bootstrap_brokers_tls" {
  description = "Lista de bootstrap brokers para conexão TLS"
  value       = aws_msk_cluster.this.bootstrap_brokers_tls
}

output "bootstrap_brokers_sasl_scram" {
  description = "Lista de bootstrap brokers para SASL/SCRAM"
  value       = aws_msk_cluster.this.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_sasl_iam" {
  description = "Lista de bootstrap brokers para SASL/IAM"
  value       = aws_msk_cluster.this.bootstrap_brokers_sasl_iam
}

output "zookeeper_connect_string" {
  description = "String de conexão para o Zookeeper"
  value       = aws_msk_cluster.this.zookeeper_connect_string
}

output "msk_security_group_id" {
  description = "ID do security group do MSK"
  value       = aws_security_group.msk_sg.id
}

output "msk_scram_secret_arn" {
  description = "ARN do secret usado para autenticação SCRAM"
  value       = var.sasl_scram_enabled && var.create_scram_secret ? aws_secretsmanager_secret.msk_scram[0].arn : null
}