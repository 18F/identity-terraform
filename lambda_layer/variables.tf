variable "source_code_filename" {
  description = "(REQUIRED) Name (with extension) of file containing function source code."
  type        = string
  default     = "lambda_function.py"
}

variable "source_dir" {
  description = <<EOM
(REQUIRED) Name of directory where source_code_filename + any other
files to be added to the ZIP file reside.
EOM
  type        = string
  default     = "src"
}

variable "zip_filename" {
  description = "(REQUIRED) Desired name (with .zip extension) of resultant output file."
  type        = string
  default     = ""
}

variable "compatible_runtimes" {
  type        = list(string)
  description = "List of runtimes that are compatible with this layer"
}

variable "layer_name" {
  type        = string
  description = "Name of layer"
}