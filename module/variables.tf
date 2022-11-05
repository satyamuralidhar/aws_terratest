variable "location" {
}
variable "aws_access_key" {
}
variable "aws_secret_key" {
}

variable "prefix" {
    default = "satya"
}

variable "tagging" {
  type = object({
    env = string
    application = string
  })
  default = {
    application = "web"
    env = "prod"
  }
  validation {
    condition = length(var.tagging.env) > 3
    error_message = "enviroment name needs to be minimum foure charecters"
  }
}

variable "subnet" {
  type = list
  default = ["192.168.1.0/24" , "192.168.2.0/24"] 
}

variable "env" {
  default = "snp"
}

variable "ami_id" {
  default = "ami-0e6329776258"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "azs" {
  type = list
  default = ["ap-south-1a" , "ap-south-1b"]
}


variable "ingress_ports" {
  type = list(number)
  default = [443,22,8080,80,8200]
}