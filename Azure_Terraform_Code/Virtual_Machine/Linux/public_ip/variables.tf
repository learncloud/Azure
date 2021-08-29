variable "node_location" {
    type = string
}
variable "resource_prefix"{
    type = string 
    // resource_prefix 이름은 terraform.tfvars에 선언되어있음
}
variable "node_address_space" {
    default = ["47.10.0.0/16"]
}
variable "node_address_prefix"{
    default = "47.10.15.0/24"
}
variable "node_count" {
    type = number
    // node_count 숫자는 terraform.tfvars에 선언되어있음
}