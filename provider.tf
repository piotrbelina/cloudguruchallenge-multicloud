terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.45"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project_name
}