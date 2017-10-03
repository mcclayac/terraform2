
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-mcclayac-dev"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-mcclayac-dev"
    key    = "terrform-project-dev"
    region = "us-east-1"
  }
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name           = "terraform-state-dev"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "terraform-up-and-running-state-mcclayac-dev"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-dev"
  }
}



resource "aws_security_group" "instance" {
  name = "terraform-example-sg-state"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "terraform-ex-state-sg"
  }
}


resource "aws_instance" "example" {
  ami = "ami-40d28157"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "terrform-example-state"
  }
}



