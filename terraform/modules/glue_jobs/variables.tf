variable "datalake_name" {
  description = "Nome base para os buckets do data lake"
  type        = string
}

################################
# Configurações dos Jobs Glue
################################

variable "glue_job_directories" {
  description = "Lista de diretórios para os scripts Glue"
  type        = list(string)
  default     = ["bronze_to_silver", "gold"]
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
      directory      = "bronze_to_silver"
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
      name           = "gold-transformation-job"
      filename       = "analytics_transformation.py"
      directory      = "gold"
      job_type       = "GoldTransformation"
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
      name           = "kafka-to-bronze-financial-transactions"
      filename       = "kafka_to_bronze.py"
      directory      = "bronze"
      job_type       = "KafkaToBronze"
      worker_type    = "G.1X"
      num_workers    = 4
      timeout        = 60
      max_retries    = 3
      glue_version   = "3.0"
      default_arguments = {
        "--job-language"               = "python"
        "--enable-continuous-cloudwatch-log" = "true"
        "--enable-metrics"             = "true"
        "--enable-spark-ui"            = "true"
        "--kafka_bootstrap_servers"    = "WILL_BE_REPLACED_DYNAMICALLY"
        "--kafka_topic"                = "financial-transactions"
        "--target_path"                = "s3://stream/bronze/financial-transactions/"
        "--schema_registry_url"        = ""
        "--kafka_security_protocol"    = "SASL_SSL"
        "--audit_logging_enabled"      = "true"
        "--audit_table"                = "s3://stream/bronze/audit/kafka-ingestion/"
        "--extra-jars"                 = "s3://aws-glue-assets-ACCOUNT-REGION/extra-jars/aws-msk-iam-auth-1.1.1-all.jar"
      }
    }
  ]
}