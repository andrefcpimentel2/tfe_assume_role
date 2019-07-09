terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "emea-se-playground-2019"
    workspaces {
      name = "tfe_assume_role_demo"
    }
  }
}

provider "aws" {

  region = "${var.region}"
}

provider "aws" {
     alias  = "aws-assume"
     assume_role {
        role_arn     = "${var.role_arn}"
        session_name = "admin-session"
     }
     region     = "${var.region}"
 }

resource "aws_instance" "jenkins" {
  provider = "aws.aws-assume"
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  user_data     = "${file("./init_install.sh")}"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
  }

  vpc_security_group_ids = [
    "${aws_security_group.jenkins_sg.id}",
  ]

  tags {
    Name  = "jenkins"
    owner = "${var.tag_owner}"
    TTL   = "${var.tag_ttl}"
  }

}


resource "aws_eip" "jenkins" {
  provider = "aws.aws-assume"
  instance = "${aws_instance.jenkins.id}"
}

# resource "aws_key_pair" "ptfe_key_pair" {
#   key_name   = "${var.key_name}"
#   public_key = "${var.public_key}"
# }

resource "aws_security_group" "jenkins_sg" {
  provider = "aws.aws-assume"
  name        = "jenkins_inbound_2"
  description = "Allow jenkins ports and ssh from Anywhere"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "ec2 machine dns" {
  value = "${aws_instance.jenkins.public_ip}"
}
