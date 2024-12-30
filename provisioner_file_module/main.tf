data "aws_ami" "linux"{
    most_recent = true

    filter{
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    
    filter{
        name = "owner-id"
        values = ["137112412989"] # Amazon's official AMI owner ID
    }
}

resource "aws_instance" "ecommerce_server" {
  ami           = data.aws_ami.linux.id
  instance_type = "t2.micro"
  key_name      = "ProvisionerKeyPair"

  vpc_security_group_ids = ["sg-00138b47ec51588d2"] # the security group that we just created
  associate_public_ip_address = true # SSH does not work without public IP. this line ensures that EC2 gets a public IP.

  provisioner "file" {
    source      = "ecommerce.conf"
    destination = "/home/ec2-user/ecommerce.conf"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./ProvisionerKeyPair.pem")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "EcommerceServer"
  }
}

output "ec2_instance_public_ip"{
    value = aws_instance.ecommerce_server.public_ip
}