variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "lifecycle_policy" {
  description = "Lifecycle policy for the ECR repository"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for the ECR repository"
  type        = map(string)
  default     = {}
}
