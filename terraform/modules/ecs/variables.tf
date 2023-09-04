variable "region" {
  type = string
}
variable "stage" {
  type = string
}
variable "app_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "ecr_image_url" {
  type = string
}
variable "container_name" {
  type = string
}
variable "container_port" {
  type = number
}
variable "lb_listener_arn" {
  type = string
}
variable "health_check_port" {
  type = string
}
variable "health_check_path" {
  type = string
}
variable "log_retention_in_days" {
  type = number
}
variable "desired_count" {
  type = number
}
