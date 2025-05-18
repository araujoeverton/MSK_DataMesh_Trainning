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
    }
  ]
}