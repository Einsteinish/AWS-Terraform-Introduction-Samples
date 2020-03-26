provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 8080
}

variable "elb_port" {
  description = "The port the elb will be listening"
  type        = number
  default     = 80
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "asg-launch-config-sample" {
  image_id          = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.nano"
  security_groups = [aws_security_group.busybox.id]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, Terraform & AWS ASG" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "busybox" {
  name = "terraform-busybox-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-sample-elb-sg"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg-sample" {
  launch_configuration = aws_launch_configuration.asg-launch-config-sample.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size = 2
  max_size = 5

  load_balancers    = [aws_elb.sample.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-sample"
    propagate_at_launch = true
  }
}

resource "aws_elb" "sample" {
  name               = "terraform-asg-sample"
  security_groups    = [aws_security_group.elb-sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # Adding a listener for incoming HTTP requests.
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

output "elb_dns_name" {
  value       = aws_elb.sample.dns_name
  description = "The domain name of the load balancer"
}
