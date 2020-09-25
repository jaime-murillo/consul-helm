variable "region" {
  default     = "West US 2"
  description = "The Azure Region to create all resources in."
}

variable "resource_prefix" {
  default     = "consul-helm-test-"
  description = "A prefix to use for all resorces."
}