# Criar uma chave KMS para criptografia
resource "aws_kms_key" "msk_key" {
  description             = "KMS key para criptografia do MSK"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name        = "${var.datalake_name}-msk-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "msk_key_alias" {
  name          = "alias/${var.datalake_name}-msk-key"
  target_key_id = aws_kms_key.msk_key.key_id
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
  
  tags = {
    Name        = "glue-jobs-sg"
    Environment = var.environment
  }
}

# Criar o cluster MSK
module "kafka_msk" {
  source = "./modules/msk_kafka"
  
  cluster_name         = "${var.datalake_name}-kafka"
  vpc_id               = aws_vpc.vpc_main.id
  vpc_cidr_blocks      = [var.vpc_cidr]
  subnet_ids           = aws_subnet.subnets[*].id
  
  kafka_version        = "3.4.0"
  number_of_broker_nodes = 3
  broker_instance_type = "kafka.m5.large"
  
  kms_key_arn          = aws_kms_key.msk_key.arn
  
  client_broker_encryption = "TLS"
  sasl_iam_enabled      = true
  sasl_scram_enabled    = false
  
  enhanced_monitoring   = "PER_BROKER"
  jmx_exporter_enabled  = true
  node_exporter_enabled = true
  
  log_retention_days    = 30
  enable_audit_logging  = true
  
  glue_security_group_id = aws_security_group.glue_sg.id
  
  # Configurações de segurança específicas para ambiente financeiro
  kafka_config_properties = {
    "auto.create.topics.enable"        = "false"
    "default.replication.factor"       = "3"
    "min.insync.replicas"              = "2"
    "num.partitions"                   = "12"
    "log.retention.hours"              = "168"  # 7 dias
    "ssl.client.auth"                  = "required"
    "authorizer.class.name"            = "kafka.security.authorizer.AclAuthorizer"
    "allow.everyone.if.no.acl.found"   = "false"
    "super.users"                      = "User:CN=admin"
  }
  
  tags = {
    Name        = "${var.datalake_name}-kafka"
    Environment = var.environment
    Project     = var.datalake_name
  }
}

# Adicionar variáveis de saída
output "kafka_bootstrap_brokers" {
  description = "Endpoints para conectar ao cluster Kafka"
  value = {
    plaintext  = module.kafka_msk.bootstrap_brokers
    tls        = module.kafka_msk.bootstrap_brokers_tls
    sasl_iam   = module.kafka_msk.bootstrap_brokers_sasl_iam
  }
}

output "zookeeper_connect_string" {
  description = "String de conexão para o Zookeeper"
  value       = module.kafka_msk.zookeeper_connect_string
}