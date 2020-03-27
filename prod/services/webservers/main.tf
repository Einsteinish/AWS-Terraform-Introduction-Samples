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

# scale out - day
resource "aws_autoscaling_schedule" "scale_out_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 5
  recurrence            = "0 9 * * *"

  autoscaling_group_name = module.webservers.asg_name
}

# scale in - night
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"
 
  autoscaling_group_name = module.webservers.asg_name
}
