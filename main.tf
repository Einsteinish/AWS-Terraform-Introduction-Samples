provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "busybox_web_server" {
  ami           = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.nano"
  vpc_security_group_ids = [aws_security_group.busybox.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, Terraform & AWS" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "busybox web server created via terraform"
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

variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 8080
}

output "public_ip" {
  value       = aws_instance.busybox_web_server.public_ip
  description = "The public IP of the web server"
}
