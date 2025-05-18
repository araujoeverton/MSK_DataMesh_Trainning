variable "crawler_name" {
  description = "Nome do crawler"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN do IAM Role para o crawler"
  type        = string
}

variable "database_name" {
  description = "Nome do banco de dados Glue para armazenar os metadados"
  type        = string
}

variable "description" {
  description = "Descrição do crawler"
  type        = string
  default     = ""
}

variable "schedule" {
  description = "Programação de execução do crawler em formato cron"
  type        = string
  default     = null
}

variable "classifiers" {
  description = "Lista de classificadores customizados"
  type        = list(string)
  default     = []
}

variable "s3_targets" {
  description = "Lista de alvos S3 para o crawler"
  type = list(object({
    path       = string
    exclusions = optional(list(string), [])
  }))
}

variable "delete_behavior" {
  description = "Comportamento de exclusão do crawler: LOG, DELETE_FROM_DATABASE, ou DEPRECATE_IN_DATABASE"
  type        = string
  default     = "DEPRECATE_IN_DATABASE"
}

variable "update_behavior" {
  description = "Comportamento de atualização do crawler: LOG ou UPDATE_IN_DATABASE"
  type        = string
  default     = "UPDATE_IN_DATABASE"
}

variable "configuration" {
  description = "Configuração JSON para o crawler"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags para o crawler"
  type        = map(string)
  default     = {}
}