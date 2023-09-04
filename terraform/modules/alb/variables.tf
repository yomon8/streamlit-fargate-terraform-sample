variable "app_name" {
  type = string
}
variable "app_port" {
  type = number
}
variable "stage" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = list(string)
}
