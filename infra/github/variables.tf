variable "owner" {
  type = string
}

variable "repository" {
  type = string
}

variable "actions_secrets" {
  type      = map(string)
  sensitive = true
}
