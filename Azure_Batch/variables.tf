variable resourcename  {
  type        = string
  default     = "Batch-RG"
  description = "resourcename-example"
}

variable location  {
  type        = string
  default     = "korea central"
  description = "resourcename-examples"
}

variable tags  {
  type        = map
  default     = {enviornment = "demo", owner = "shan", purpose = "TFdemo" }
}
