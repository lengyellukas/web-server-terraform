variable "prefix" {
  description = "The prefix which should be used for all resources in this project."
  default = "lukas"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "eastus"
}

variable "username" {
  description = "Username of the Azure user with sufficient rights."
  default = "odl_user_203793@udacityhol.onmicrosoft.com"
}

variable "password" {
  description = "Username password of the Azure user with sufficient rights."
  default = "aksy86UWP*hh"
}

variable "tags" {
   description = "Map of the tags to use for the resources that are deployed."
   type        = map(string)
   default = {
      environment = "test"
   }
}

variable "project" {
  description = "Name of the project"
  default = "nd082-Azure-Cloud-DevOps"
}

variable "instance_count" {
  description = "Set the number of virtual machines to be created."
  default = 2
}