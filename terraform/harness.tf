terraform {  
    required_providers {  
        harness = {  
            source = "harness/harness"  
            version = "0.30.2"
        }  
    }  
}

variable "key" {
  description = "Harness Key"
  type        = string
  sensitive   = true

}

variable "account" {
  description = "Harness Account"
  type        = string
  sensitive   = true

}

provider "harness" {  
    endpoint   = "https://app.harness.io/gateway"  
    account_id = var.account  
    platform_api_key    = var.key
}
