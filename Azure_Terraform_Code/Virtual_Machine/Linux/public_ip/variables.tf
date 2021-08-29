variable "node_location" {
    type = string
}
variable "resource_prefix"{
    type = string
}
variable "node_address_space" {
    default = ["10.0.0.0/8"]
}
variable "node_address_prefix"{
    default = "10.1.0.0/16"
}
variable "node_count" {
    type = number
}