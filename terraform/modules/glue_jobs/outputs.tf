
output "glue_scripts_bucket" {
  description = "Nome do bucket para scripts do Glue"
  value       = aws_s3_bucket.glue_scripts.bucket
}

output "glue_jobs" {
  description = "Detalhes dos Glue Jobs criados"
  value = {
    for name, job in aws_glue_job.glue_jobs : name => {
      name = job.name
      worker_type = job.worker_type
      num_workers = job.number_of_workers
      script_location = job.command[0].script_location
    }
  }
}