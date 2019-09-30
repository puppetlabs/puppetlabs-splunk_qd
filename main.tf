provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "search_head" {
  name        = "splunk_search_head"
  description = "Used in the terraform"
  vpc_id = "vpc-0e24ca0cbb4660bde"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9997
    to_port     = 9997
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

resource "aws_instance" "search_head" {
  connection {
    user = "ec2-user"
    host = "${self.public_ip}"
  }
  instance_type = "m5.large"
  key_name = "ryan_mbp"
  ami = "ami-0f2176987ee50226e"
  vpc_security_group_ids = ["${aws_security_group.search_head.id}","sg-02cf02361bcd51e54"]
  subnet_id = "subnet-020e959a848f88088"
  tags = {
    termination_date = "indefinite"
  }
  root_block_device {
    volume_size = 50
  }
  provisioner "puppet" {
    server      = "portland-5y3lgkjjdb5bednl.us-west-2.opsworks-cm.io"
    server_user = "ec2-user"
    autosign    = false
    open_source = false
  }
}

resource "aws_instance" "forwarder0" {
  connection {
    user = "ec2-user"
    host = "${self.public_ip}"
  }
  instance_type = "t2.micro"
  key_name = "ryan_mbp"
  ami = "ami-0f2176987ee50226e"
  vpc_security_group_ids = ["sg-02cf02361bcd51e54"]
  subnet_id = "subnet-020e959a848f88088"
  tags = {
    termination_date = "indefinite"
  }
  provisioner "puppet" {
    server      = "portland-5y3lgkjjdb5bednl.us-west-2.opsworks-cm.io"
    server_user = "ec2-user"
    autosign    = false
    open_source = false
  }
}
resource "aws_instance" "forwarder1" {
  connection {
    user = "ec2-user"
    host = "${self.public_ip}"
  }
  instance_type = "t2.micro"
  key_name = "ryan_mbp"
  ami = "ami-0f2176987ee50226e"
  vpc_security_group_ids = ["sg-02cf02361bcd51e54"]
  subnet_id = "subnet-020e959a848f88088"
  tags = {
    termination_date = "indefinite"
  }
  provisioner "puppet" {
    server      = "portland-5y3lgkjjdb5bednl.us-west-2.opsworks-cm.io"
    server_user = "ec2-user"
    autosign    = false
    open_source = false
  }

}

resource "aws_instance" "forwarder2" {
  connection {
    user = "ec2-user"
    host = "${self.public_ip}"
  }
  instance_type = "t2.micro"
  key_name = "ryan_mbp"
  ami = "ami-0f2176987ee50226e"
  vpc_security_group_ids = ["sg-02cf02361bcd51e54"]
  subnet_id = "subnet-020e959a848f88088"
  tags = {
    termination_date = "indefinite"
  }
  provisioner "puppet" {
    server      = "portland-5y3lgkjjdb5bednl.us-west-2.opsworks-cm.io"
    server_user = "ec2-user"
    autosign    = false
    open_source = false
  }

}

# # Create a VPC to launch our instances into
# resource "aws_vpc" "default" {
#   cidr_block = "10.0.0.0/16"
# }

# # Create an internet gateway to give our subnet access to the outside world
# resource "aws_internet_gateway" "default" {
#   vpc_id = "${aws_vpc.default.id}"
# }

# # Grant the VPC internet access on its main route table
# resource "aws_route" "internet_access" {
#   route_table_id         = "${aws_vpc.default.main_route_table_id}"
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = "${aws_internet_gateway.default.id}"
# }

# # Create a subnet to launch our instances into
# resource "aws_subnet" "default" {
#   vpc_id                  = "${aws_vpc.default.id}"
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
# }

# A security group for the ELB so it is accessible via the web
# resource "aws_security_group" "elb" {
#   name        = "terraform_example_elb"
#   description = "Used in the terraform"
#   #vpc_id      = "${aws_vpc.default.id}"
#   vpc_id = "vpc-0e24ca0cbb4660bde"

#   # HTTP access from anywhere
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # outbound internet access
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# Our default security group to access
# the instances over SSH and HTTP
# resource "aws_security_group" "default" {
#   name        = "terraform_example"
#   description = "Used in the terraform"
#   vpc_id      = "${aws_vpc.default.id}"

#   # SSH access from anywhere
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # HTTP access from the VPC
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]
#   }

#   # outbound internet access
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_elb" "web" {
#   name = "terraform-example-elb"

#   subnets         = ["${aws_subnet.default.id}"]
#   security_groups = ["${aws_security_group.elb.id}"]
#   instances       = ["${aws_instance.web.id}"]

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }
# }
