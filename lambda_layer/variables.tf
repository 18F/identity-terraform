variable "source_code_filename" {
  description = "Name (with extension) of file containing function source code."
  type        = string
}

variable "source_dir" {
  description = <<EOM
Name of directory where source_code_filename + any other
files to be added to the ZIP file reside.
EOM
  type        = string
}

variable "zip_filename" {
  description = "Desired name (with .zip extension) of resultant output file."
  type        = string
}

variable "compatible_runtimes" {
  type        = list(string)
  description = "List of runtimes that are compatible with this layer"
}

variable "layer_name" {
  type        = string
  description = "Name of layer"
}