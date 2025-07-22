terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" 
}


resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "http_server_sg" {
  name   = "http_server_sg"
  vpc_id = "vpc-0d58c1e456c858183"


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "http_server_sg"
  }
}

resource "aws_instance" "http_server" {
  ami                    = "ami-0b32d400456908bf9"
  key_name               = "mywebserver"
  instance_type          = "t3.medium"
  subnet_id              = "subnet-0e0a9570bd083ad3a"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install httpd -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo usermod -a -G apache ec2-user",
      "sudo chmod 755 /var/www/html",
      "cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>My Simple Static Website</title>
    <style>
      body { font-family: Arial, sans-serif; background-color: #f4f4f4; text-align: center; padding: 50px; }
      h1 { color: #333; }
      p { font-size: 18px; color: #666; }
    </style>
</head>
<body>
    <h1>Welcome to My Static Website!</h1>
    <p>Hosted on EC2 instance</p>
</body>
</html>
EOF"
    ]
  }
