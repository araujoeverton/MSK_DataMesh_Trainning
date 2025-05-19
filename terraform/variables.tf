################################
# Global Configuration
################################

variable "region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default     = {
    ManagedBy   = "terraform"
    Environment = "dev"
    Project     = "financial-data-lake"
  }
}

################################
# VPC Configuration
################################

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "Lista de CIDRs para as subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Lista de availability zones para usar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

################################
# Data Lake Configuration
################################

variable "datalake_name" {
  description = "Nome base para os buckets do data lake"
  type        = string
  default     = "financial-datalake"
}

################################
# Glue Jobs Configuration
################################

variable "glue_job_directories" {
  description = "Lista de diretórios para os scripts Glue"
  type        = list(string)
  default     = ["bronze", "bronze_to_silver", "gold"]
}

variable "glue_jobs" {
  description = "Configurações dos Jobs Glue"
  type = list(object({
    name           = string
    filename       = string
    directory      = string
    job_type       = string
    worker_type    = string
    num_workers    = number
    timeout        = number
    max_retries    = number
    glue_version   = string
    default_arguments = map(string)
  }))
  default = [
    {
      name           = "bronze-to-silver-job"
      filename       = "raw_to_processed.py"
      directory      = "silver"
      job_type       = "BronzeToSilver"
      worker_type    = "G.1X"
      num_workers    = 2
      timeout        = 60
      max_retries    = 2
      glue_version   = "3.0"
      default_arguments = {
        "--job-language" = "python"
        "--enable-continuous-cloudwatch-log" = "true"
        "--enable-metrics" = "true"
      }
    },
    {
      name           = "kafka-to-bronze"
      filename       = "kafka_to_bronze.py"
      directory      = "bronze"
      job_type       = "KafkaToBronze"
      worker_type    = "G.1X"
      num_workers    = 4
      timeout        = 120
      max_retries    = 3
      glue_version   = "3.0"
      default_arguments = {
        "--job-language" = "python"
        "--enable-continuous-cloudwatch-log" = "true"
        "--enable-metrics" = "true"
        "--enable-spark-ui" = "true"
        "--kafka_topic" = "financial-transactions"
        "--schema_registry_url" = ""
        "--kafka_security_protocol" = "SASL_SSL"
        "--audit_logging_enabled" = "true"
        "--extra-jars" = "s3://aws-glue-assets-715841344869-us-east-1/extra-jars/aws-msk-iam-auth-1.1.1-all.jar"
      }
    }
  ]
}

################################
# MSK Kafka Configuration
################################

variable "kafka_version" {
  description = "Versão do Kafka para o cluster MSK"
  type        = string
  default     = "3.4.0"
}

variable "msk_broker_nodes" {
  description = "Número de nós broker (deve ser múltiplo do número de subnets)"
  type        = number
  default     = 3
}

variable "msk_broker_instance_type" {
  description = "Tipo de instância para os brokers do MSK"
  type        = string
  default     = "kafka.m5.large"
}

variable "msk_client_broker_encryption" {
  description = "Tipo de criptografia entre clientes e brokers (PLAINTEXT, TLS, TLS_PLAINTEXT)"
  type        = string
  default     = "TLS"
}

variable "msk_sasl_iam_enabled" {
  description = "Habilitar autenticação IAM via SASL"
  type        = bool
  default     = true
}

variable "msk_sasl_scram_enabled" {
  description = "Habilitar autenticação SCRAM via SASL"
  type        = bool
  default     = false
}

variable "msk_enhanced_monitoring" {
  description = "Nível de monitoramento aprimorado (DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION)"
  type        = string
  default     = "PER_BROKER"
}

variable "msk_jmx_exporter_enabled" {
  description = "Habilitar exportador JMX para Prometheus"
  type        = bool
  default     = true
}

variable "msk_node_exporter_enabled" {
  description = "Habilitar exportador Node para Prometheus"
  type        = bool
  default     = true
}

variable "msk_log_retention_days" {
  description = "Dias de retenção para logs no CloudWatch"
  type        = number
  default     = 30
}

variable "msk_enable_audit_logging" {
  description = "Habilitar logs de auditoria"
  type        = bool
  default     = true
}

variable "msk_config_properties" {
  description = "Mapa de propriedades de configuração do Kafka"
  type        = map(string)
  default     = {
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
}