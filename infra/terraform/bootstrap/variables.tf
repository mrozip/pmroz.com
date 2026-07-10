variable "state_resource_group_name" {
  description = "Name of the resource group that contains the Terraform state backend."
  type        = string
  default     = "rg-hugo-pmroz-state-shared"
}

variable "state_storage_account_name" {
  description = "Globally unique Azure Storage account name for Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "state_storage_account_name must be 3-24 lowercase letters or numbers."
  }
}

variable "state_container_name" {
  description = "Blob container name for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "state_location" {
  description = "Azure region for the Terraform state backend."
  type        = string
  default     = "eastus2"
}

variable "assign_current_principal_blob_data_contributor" {
  description = "Assign Storage Blob Data Contributor to the GitHub Actions Azure principal for backend access."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to Terraform state resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "pmroz.com"
    purpose    = "terraform-state"
  }
}
