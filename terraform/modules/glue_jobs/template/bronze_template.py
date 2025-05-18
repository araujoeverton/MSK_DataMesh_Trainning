import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
from datetime import datetime

# Parâmetros do job
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'source_bucket', 'source_prefix', 'target_path', 'file_format'])

# Inicializando o contexto Spark e Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Obtendo parâmetros
source_bucket = args['source_bucket']
source_prefix = args['source_prefix']
target_path = args['target_path']
file_format = args['file_format']

print(f"Iniciando ingestão de dados do bucket {source_bucket}/{source_prefix} para {target_path}")

# Cliente S3
s3_client = boto3.client('s3')

# Listar arquivos no bucket de origem
response = s3_client.list_objects_v2(Bucket=source_bucket, Prefix=source_prefix)
files_to_process = []

if 'Contents' in response:
    for obj in response['Contents']:
        if obj['Key'].endswith(f'.{file_format}'):
            files_to_process.append(obj['Key'])

print(f"Encontrados {len(files_to_process)} arquivos para processamento")

# Processar cada arquivo
for file_key in files_to_process:
    print(f"Processando arquivo: {file_key}")
    
    # Definir o caminho de entrada
    input_path = f"s3://{source_bucket}/{file_key}"
    
    # Gerar nome do arquivo de saída com timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_name = file_key.split('/')[-1].split('.')[0]
    output_path = f"{target_path}/{file_name}_{timestamp}"
    
    # Ler o arquivo com base no formato
    if file_format.lower() == 'csv':
        df = spark.read.option("header", "true").option("inferSchema", "true").csv(input_path)
    elif file_format.lower() == 'json':
        df = spark.read.json(input_path)
    elif file_format.lower() == 'parquet':
        df = spark.read.parquet(input_path)
    else:
        raise ValueError(f"Formato de arquivo não suportado: {file_format}")
    
    # Adicionar metadados
    df = df.withColumn("source_file", spark.sparkContext.broadcast(file_key))
    df = df.withColumn("ingestion_timestamp", spark.sparkContext.broadcast(timestamp))
    
    # Salvar o arquivo no destino em formato Parquet
    print(f"Salvando dados em: {output_path}")
    df.write.mode("overwrite").parquet(output_path)
    
    print(f"Arquivo {file_key} processado com sucesso")

print("Ingestão de dados concluída com sucesso!")

job.commit()