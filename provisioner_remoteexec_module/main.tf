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

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("./ProvisionerKeyPair.pem")
        host = self.public_ip
    }

  provisioner "remote-exec"{
    #when = "create"
    #when = "destroy"
    inline = [ 
        "echo 'Hello from Terraform!' > /home/ec2-user/testfile.txt"
     ]
  }

  tags = {
    Name = "EcommerceServer"
  }
}

output "server_public_IP" {
  value = aws_instance.ecommerce_server.public_ip
}

