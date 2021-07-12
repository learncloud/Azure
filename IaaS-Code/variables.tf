#variable zone 
#https://github.com/shan0809/Jumpstart-Terraform-0.12-on-Azure
#foretch문

variable prefix {
  type        = string
  default     = "jasie"
  description = "description"
}

variable resourcename  {
  type        = string
  default     = "Terraform-RG"
  description = "resourcename-example"
}

variable location  {
  type        = string
  default     = "korea central"
  description = "resourcename-example"
}

variable tags  {
  type        = map
  default     = {enviornment = "demo", owner = "shan", purpose = "TFdemo" }
}

variable storagename {
    type        = string
    default     = "jasminstr1102"
    description = "wow-create"
}

variable "containername" {
    type        = string
    default     = "jasmin-contain"
    description = "wow-create-contain"
}


# variable port  {
#   type        = string
#   default     = "80"
#   description = "port-example"
# }

# variable prefix {
#   type        = string
#   default     = "jasie"
#   description = "description"
# }

# variable idd {
#   type        = string
#   default     = "jjh"
#   description = "description"
# }

# variable pass {
#   type        = string
#   default     = "wjdwogjs1!!!"
#   description = "description"
# }


