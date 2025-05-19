import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, from_json, explode, to_timestamp, current_timestamp, lit
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, TimestampType, ArrayType

# Obter parâmetros do job
args = getResolvedOptions(sys.argv, [
    'JOB_NAME', 
    'kafka_bootstrap_servers', 
    'kafka_topic', 
    'target_path',
    'schema_registry_url',
    'kafka_security_protocol',
    'audit_logging_enabled',
    'audit_table'
])

# Inicializar o contexto Spark e Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configurações de segurança para o Kafka
kafka_options = {
    "kafka.bootstrap.servers": args['kafka_bootstrap_servers'],
    "subscribe": args['kafka_topic'],
    "startingOffsets": "latest",
    "kafka.security.protocol": args['kafka_security_protocol']
}

# Se estiver usando autenticação IAM (modo AWS MSK IAM)
if args['kafka_security_protocol'] == "SASL_SSL":
    kafka_options.update({
        "kafka.sasl.mechanism": "AWS_MSK_IAM",
        "kafka.sasl.jaas.config": "software.amazon.msk.auth.iam.IAMLoginModule required;",
        "kafka.sasl.client.callback.handler.class": "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
    })

# Definir o esquema dos dados (exemplo)
# Este esquema deve ser adaptado aos seus dados reais
schema = StructType([
    StructField("id", StringType(), True),
    StructField("timestamp", StringType(), True),
    StructField("customer_id", StringType(), True),
    StructField("transaction_type", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("currency", StringType(), True),
    StructField("status", StringType(), True),
    StructField("metadata", StringType(), True)
])

# Ler do Kafka
kafka_df = spark.readStream \
    .format("kafka") \
    .options(**kafka_options) \
    .load()

# Converter o valor do Kafka para o esquema definido
parsed_df = kafka_df \
    .selectExpr("CAST(key AS STRING)", "CAST(value AS STRING)", "topic", "partition", "offset", "timestamp") \
    .select(
        col("key"),
        from_json(col("value"), schema).alias("data"),
        col("topic"),
        col("partition"),
        col("offset"),
        col("timestamp").alias("kafka_timestamp")
    ) \
    .select(
        "key",
        "data.*",
        "topic",
        "partition",
        "offset",
        "kafka_timestamp"
    )

# Adicionar metadados importantes para auditoria
enhanced_df = parsed_df \
    .withColumn("ingestion_timestamp", current_timestamp()) \
    .withColumn("data_source", lit(args['kafka_topic'])) \
    .withColumn("transaction_timestamp", to_timestamp(col("timestamp")))

# Gravar na camada Bronze
output_path = args['target_path']
checkpoint_path = f"{output_path}/_checkpoints"

query = enhanced_df \
    .writeStream \
    .format("parquet") \
    .partitionBy("transaction_type") \
    .option("path", output_path) \
    .option("checkpointLocation", checkpoint_path) \
    .trigger(processingTime="1 minute") \
    .start()

# Se o logging de auditoria estiver habilitado, gravar metadados na tabela de auditoria
if args['audit_logging_enabled'].lower() == 'true':
    audit_df = enhanced_df \
        .select(
            col("id"),
            col("kafka_timestamp"),
            col("ingestion_timestamp"),
            col("topic"),
            col("partition"),
            col("offset"),
            current_timestamp().alias("processed_timestamp")
        )
    
    # Gravar dados de auditoria
    audit_query = audit_df \
        .writeStream \
        .format("parquet") \
        .option("path", args['audit_table']) \
        .option("checkpointLocation", f"{args['audit_table']}/_checkpoints") \
        .trigger(processingTime="1 minute") \
        .start()

# Aguardar a conclusão do processamento
query.awaitTermination()
if args['audit_logging_enabled'].lower() == 'true':
    audit_query.awaitTermination()

job.commit()