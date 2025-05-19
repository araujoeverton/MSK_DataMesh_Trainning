variable "cluster_name" {
  description = "Nome do cluster MSK"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o cluster MSK será criado"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "Lista de blocos CIDR da VPC para configuração do security group"
  type        = list(string)
}

variable "subnet_ids" {
  description = "IDs das subnets para o cluster MSK (mínimo de 2 subnet em AZs diferentes)"
  type        = list(string)
}

variable "kafka_version" {
  description = "Versão do Kafka para o cluster MSK"
  type        = string
  default     = "2.8.1"
}

variable "number_of_broker_nodes" {
  description = "Número de nós broker (deve ser múltiplo do número de subnets)"
  type        = number
  default     = 3
}

variable "broker_instance_type" {
  description = "Tipo de instância para os brokers do MSK"
  type        = string
  default     = "kafka.m5.large"
}

variable "ebs_volume_size" {
  description = "Tamanho do volume EBS para cada broker (em GiB)"
  type        = number
  default     = 1000
}

variable "provisioned_throughput_enabled" {
  description = "Ativar throughput provisionado para volumes EBS"
  type        = bool
  default     = false
}

variable "volume_throughput" {
  description = "Throughput provisionado para volumes EBS (em MiB/s)"
  type        = number
  default     = 250
}

variable "client_broker_encryption" {
  description = "Tipo de criptografia entre clientes e brokers (PLAINTEXT, TLS, TLS_PLAINTEXT)"
  type        = string
  default     = "TLS"
}

variable "kms_key_arn" {
  description = "ARN da chave KMS para criptografia em repouso"
  type        = string
}

variable "sasl_iam_enabled" {
  description = "Habilitar autenticação IAM via SASL"
  type        = bool
  default     = true
}

variable "sasl_scram_enabled" {
  description = "Habilitar autenticação SCRAM via SASL"
  type        = bool
  default     = false
}

variable "create_scram_secret" {
  description = "Criar um secret no Secrets Manager para autenticação SCRAM"
  type        = bool
  default     = false
}

variable "scram_username" {
  description = "Nome de usuário para autenticação SCRAM"
  type        = string
  default     = "kafka-user"
  sensitive   = true
}

variable "scram_password" {
  description = "Senha para autenticação SCRAM"
  type        = string
  default     = ""
  sensitive   = true
}

variable "secret_recovery_window_in_days" {
  description = "Período de recuperação do secret no Secrets Manager"
  type        = number
  default     = 7
}

variable "certificate_authority_arns" {
  description = "Lista de ARNs de autoridades certificadoras para autenticação TLS"
  type        = list(string)
  default     = []
}

variable "enhanced_monitoring" {
  description = "Nível de monitoramento aprimorado (DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION)"
  type        = string
  default     = "PER_BROKER"
}

variable "jmx_exporter_enabled" {
  description = "Habilitar exportador JMX para Prometheus"
  type        = bool
  default     = true
}

variable "node_exporter_enabled" {
  description = "Habilitar exportador Node para Prometheus"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Dias de retenção para logs no CloudWatch"
  type        = number
  default     = 7
}

variable "enable_audit_logging" {
  description = "Habilitar logs de auditoria"
  type        = bool
  default     = true
}

variable "s3_logs_enabled" {
  description = "Habilitar logs no S3"
  type        = bool
  default     = false
}

variable "s3_logs_bucket" {
  description = "Nome do bucket S3 para logs"
  type        = string
  default     = ""
}

variable "s3_logs_prefix" {
  description = "Prefixo para logs no S3"
  type        = string
  default     = "msk-logs"
}

variable "glue_security_group_id" {
  description = "ID do security group usado pelos jobs do Glue"
  type        = string
}

variable "kafka_config_properties" {
  description = "Mapa de propriedades de configuração do Kafka"
  type        = map(string)
  default     = {
    "auto.create.topics.enable"        = "false"
    "default.replication.factor"       = "3"
    "min.insync.replicas"              = "2"
    "num.io.threads"                   = "8"
    "num.network.threads"              = "5"
    "num.partitions"                   = "1"
    "num.replica.fetchers"             = "2"
    "replica.lag.time.max.ms"          = "30000"
    "socket.receive.buffer.bytes"      = "102400"
    "socket.request.max.bytes"         = "104857600"
    "socket.send.buffer.bytes"         = "102400"
    "unclean.leader.election.enable"   = "false"
    "zookeeper.session.timeout.ms"     = "18000"
    "log.retention.hours"              = "168"
    "log.segment.bytes"                = "1073741824"
    "log.cleaner.enable"               = "true"
    "compression.type"                 = "producer"
  }
}

variable "tags" {
  description = "Tags para recursos do MSK"
  type        = map(string)
  default     = {}
}