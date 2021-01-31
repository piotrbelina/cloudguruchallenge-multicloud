variable "upload_bucket_prefix" {
  default = "piotrbelina-acg-challenge"
  type    = string
}

variable "website_bucket_prefix" {
  default = "piotrbelina-acg-challenge"
  type    = string
}

variable "vision_bucket_prefix" {
  default = "piotrbelina-acg-challenge"
  type    = string
}

variable "cognito_pool_name" {
  default = "acg_multi_cloud_challenge"
  type    = string
}

variable "gcp_project_name" {
  type    = string
}

variable "azure_resource_group_name" {
  default = "acg-challenge"
  type    = string
}

variable "azure_resource_group_location" {
  default = "germanywestcentral"
  type    = string
}

variable "lambda_arn" {
  type    = string
}