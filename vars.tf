variable "project_name" {
  description = "The new application project name you are onboarding"
  type        = string
}

variable "org_name" {
  description = "The harness organization"
  type        = string
}

variable "repo_name" {
  description = "The new repo name you are onboarding"
  type        = string
}

variable "repo_org" {
  description = "The new repo organization you are onboarding"
  type        = string
}

variable "k8s_ns" {
  description = "The kubernetes namespace"
  type        = string
}

variable "github_secret" {
  description = "Github secret"
  type        = string
  sensitive   = true

}