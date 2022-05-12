output "zip_output_path" {
  description = "Output path/filename of ZIP file created from source code filename."
  value       = data.archive_file.lambda.output_path
}

output "zip_output_base64sha256" {
  description = "base64-encoded SHA256 checksum of ZIP file."
  value       = data.archive_file.lambda.output_base64sha256
}

output "resource_check" {
  description = "ID of null_resource (changes when triggered)."
  value       = null_resource.source_hash_check.id
}