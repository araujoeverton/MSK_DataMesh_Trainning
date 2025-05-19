resource "aws_security_group" "msk_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for MSK cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id

  # Permitir tráfego entre nós do cluster
  ingress {
    from_port   = 9092
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow Kafka plaintext, TLS and IAM traffic within VPC"
  }

  # Permitir tráfego para Zookeeper
  ingress {
    from_port   = 2181
    to_port     = 2182
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow Zookeeper traffic within VPC"
  }

  # Permitir todo o tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-sg"
  })
}

resource "aws_cloudwatch_log_group" "msk_broker_logs" {
  name              = "/aws/msk/${var.cluster_name}/broker-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "msk_audit_logs" {
  count             = var.enable_audit_logging ? 1 : 0
  name              = "/aws/msk/${var.cluster_name}/audit-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  
  tags = var.tags
}

resource "aws_msk_configuration" "this" {
  name              = "${var.cluster_name}-config"
  kafka_versions    = [var.kafka_version]
  server_properties = join("\n", [for k, v in var.kafka_config_properties : "${k}=${v}"])
}

resource "aws_msk_cluster" "this" {
  cluster_name           = var.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = [aws_security_group.msk_sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size
        provisioned_throughput {
          enabled           = var.provisioned_throughput_enabled
          volume_throughput = var.provisioned_throughput_enabled ? var.volume_throughput : null
        }
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.client_broker_encryption
      in_cluster    = true
    }
    encryption_at_rest_kms_key_arn = var.kms_key_arn
  }

  client_authentication {
    sasl {
      iam   = var.sasl_iam_enabled
      scram = var.sasl_scram_enabled
    }
    tls {
      certificate_authority_arns = var.certificate_authority_arns
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_broker_logs.name
      }
      s3 {
        enabled = var.s3_logs_enabled
        bucket  = var.s3_logs_enabled ? var.s3_logs_bucket : null
        prefix  = var.s3_logs_enabled ? "${var.s3_logs_prefix}/${var.cluster_name}/broker-logs/" : null
      }
    }
  }

  # Configurações para ambientes de produção
  enhanced_monitoring = var.enhanced_monitoring
  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.jmx_exporter_enabled
      }
      node_exporter {
        enabled_in_broker = var.node_exporter_enabled
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to configuration info revision as it may change automatically
      configuration_info[0].revision
    ]
  }
}

# Criar grupo de segurança para o cluster MSK
resource "aws_security_group_rule" "allow_glue_to_msk" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9094
  protocol                 = "tcp"
  source_security_group_id = var.glue_security_group_id
  security_group_id        = aws_security_group.msk_sg.id
  description              = "Allow Glue jobs to connect to MSK"
}

# Configurar tópicos do Kafka (opcional)
resource "aws_msk_scram_secret_association" "this" {
  count = var.sasl_scram_enabled && var.create_scram_secret ? 1 : 0

  cluster_arn     = aws_msk_cluster.this.arn
  secret_arn_list = [aws_secretsmanager_secret.msk_scram[0].arn]
}

resource "aws_secretsmanager_secret" "msk_scram" {
  count = var.sasl_scram_enabled && var.create_scram_secret ? 1 : 0

  name                    = "${var.cluster_name}-scram-secret"
  description             = "Secret for MSK SCRAM authentication for ${var.cluster_name}"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "msk_scram" {
  count = var.sasl_scram_enabled && var.create_scram_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.msk_scram[0].id
  secret_string = jsonencode({
    username = var.scram_username
    password = var.scram_password
  })
}