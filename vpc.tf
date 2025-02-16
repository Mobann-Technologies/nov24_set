#1 Create a VPC
resource "aws_vpc" "sam-vpc" {
  cidr_block       = "25.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"

  tags = {
    Name = "sam-vpc"
    Environment = "devops"
  }
}

#2 Create IGW
resource "aws_internet_gateway" "sam-igw" {
  vpc_id = aws_vpc.sam-vpc.id

  tags = {
    Name = "sam-igw"
    Environment = "devops"
  }
}

#3 Create a public RT
resource "aws_route_table" "sam-pubrt" {
  vpc_id = aws_vpc.sam-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sam-igw.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.sam-igw.id
#   }

  tags = {
    Name = "sam-pubrt"
    Environment = "devops"
  }
}

#4 Create a Public subnet in eu-west-2a
resource "aws_subnet" "sam-pubsn-2a" {
  vpc_id     = aws_vpc.sam-vpc.id
  availability_zone = "eu-west-2a"
  cidr_block = "25.0.0.0/24"

  tags = {
    Name = "sam-pubsn-2a"
    Environment = "devops"
  }
}

#5 Associate the subnet with the RT
resource "aws_route_table_association" "sam-a" {
  subnet_id      = aws_subnet.sam-pubsn-2a.id
  route_table_id = aws_route_table.sam-pubrt.id
}

#6 Create a security group
resource "aws_security_group" "sam-pubsg" {
  name        = "sam-pubsg"
  description = "Access to SSH and RDP from a single IP address & https from anywhere"
  vpc_id      = aws_vpc.sam-vpc.id

    ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["198.167.100.20/32"]
    #ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["198.167.100.20/32"]
    #ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
    }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "sam-pubsg"
    Environment = "devops"
  }
}

#7 Create a network interface with an IP in the subnet that was created in step 4
resource "aws_network_interface" "sam-eni-2a" {
  subnet_id       = aws_subnet.sam-pubsn-2a.id
  private_ips     = ["25.0.0.4"]
  security_groups = [aws_security_group.sam-pubsg.id]

#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 1
#   }
}

#8 Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "sam-eip1" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.sam-eni-2a.id
  associate_with_private_ip = "25.0.0.4"

  depends_on = [aws_internet_gateway.sam-igw]
}

#9 Launch an EC2 instance.
resource "aws_instance" "sam-server1" {
  ami           = "ami-08447c25f2e9dc66c" # es-west-2, ubuntu 20.04
  instance_type = "t2.micro"
    key_name      = "mo-london-kp"

  network_interface {
    network_interface_id = aws_network_interface.sam-eni-2a.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 12
  }

  tags = {
    Name = "sam-server1"
    Environment = "devops"
  }
}