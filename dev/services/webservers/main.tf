provider "aws" {
  region = "us-east-1"
}

module "webservers" {
  source = "../../../modules/services/webservers"
  cluster_name = "webservers-dev"
}    
