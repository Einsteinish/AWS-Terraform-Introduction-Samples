provider "aws" {
  region = "us-east-1"
}

module "webservers" {
  source = "../../../modules/services/webservers"
  cluster_name = "webservers-dev"
  instance_type = "t2.nano"
  min_size      = 2
  max_size      = 5
  desired_capacity  = 2
}    
