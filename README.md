# Understanding Terraform Provisioner: A Beginner's Tutorial
<p align="center">
  Getting Started with Infrastructure Automation via Terraform Provisioners
</p>
<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/4ccccc2a-d168-4324-810e-4c0c3a110c46" />
</p>


### What is a Provisioner? <br/>
A provisioner is a mechanism that is used to execute commands or scripts on a resource after the resource has been created. It is part of the infrastructure deployment process, allowing you to install the necessary software or apply the required configurations.<br/>

There are three types of provisioners:

1. File Provisioner: Used to transfer files or directories from the local machine to a remote resource.

2. Remote-Exec Provisioner: Used to execute commands on the remote resource using SSH or WinRM, which is why the remote resource must support SSH or WinRM.

3. Local-Exec Provisioner: Used to execute commands on the local machine (the machine running Terraform).

### File Provisioner 
As we mentioned earlier, it is used to transfer files or directories from a local machine to remote resources. <br/>

Let's imagine we will create an e-commerce platform and want to host our backend on EC2 in AWS. We will need to define critical details such as database connections, payment gateway configurations, and so on for the backend server. <br/>

In this case, we need to use the `File Provisioner` to upload the configuration file from the local machine to the EC2 server.<br/>

We need to create a configuration file named `ecommerce.conf` and add some fake details to it.
<p align="center">
  <img src="https://github.com/user-attachments/assets/8f9a6442-4108-48ec-a805-b7c1de16d190" />
</p>
 <br/>

```
[database]
host = "database info"
port = 1234
username = firat
password = firat1234
```
Our database configuration file is ready, and we can start writing the Terraform configuration code to create EC2 in AWS. <br/>

> You can check how to configure `AWS CLI` if you have not.

<br/>Create a folder and move your configuration file under the folder because we want to keep the configuration file where our main.tf file is. <br/>

Now we need to write our EC2 configuration code and get started with fetching the latest Linux AMI. I will use Linux because it will not be charged for the operating system additionally. <br/>

> We need a key pair for EC2 creation and connection. Please follow the steps here before moving forward.

<br/>
Here is the data block configuration code.  <br/>

```
# Get the latest Amazon Linux 2 AMI
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
```
 <br/>
 
The `filter` is used to narrow down the results that come from the provider. You do not have to use it. It is optional. 

<br/>

`name` is a key that is used by the filter. For example, the result will be filtered by name. If you want to filter the result by `architecture`, then you need to create code like that below.
 <br/>
```
filter{
    name = "architecture"
    values = ["x86_64"]
}
```
<br/>

Now, we are able to fetch the latest `AMI` , and it's time to create our EC2 instance. In this case, we will use the default security group that AWS provides us.

<br/>

> We need to make sure that our default security group allows SSH (port 22) from our IP address. If it allows `All traffic`, then you do not have to configure anything. However, keeping your security group as `All traffic` is not recommended.


<br/>

Let's check our security group details first. Go to the EC2 page and hit the `Security Groups` on the left side. 

<br/>  <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/e72f727f-def7-4dd9-a707-a2831ca64a9e" />
</p>
 <br/>

Go to Inbound rules and hit `Edit Inbound rules` <br/>
<p>
   <img src="https://github.com/user-attachments/assets/051c9e57-2799-486f-88f3-eddddb35e6be" />
</p>
 <br/>

Hit `Add rule` and add the line like the one below, and then hit `Save rules`
<p align="center">
   <img src="https://github.com/user-attachments/assets/eaa325de-236f-4bb1-bd0c-f939700cb60b" />
</p>

As I mentioned before, if your security group allows all traffic, you do not have to set up SSH. Let’s create an EC2 instance code.  <br/>

```
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
```

 <br/>
 
We need to test our code after creation; that is why we need a public IP. We will use the `out` keyword to output the public IP.  <br/>

```
output "ec2_instance_public_ip"{
    value = aws_instance.ecommerce_server.public_ip
}
```

 <br/>
 
Our configuration is ready now. We will execute `terraform init`, `terraform plan`, and `terraform apply` commands respectively and create an EC2 instance. 

<br/>

The entire code should be like the one below. <br/>

```
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
```

 <br/>
 
Let's start with the `terraform init` command. You should see a similar following result when you execute the command. <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/178a37a3-5452-43e4-a609-c15b6fe76f2a" />
</p>

<br/>

Time to execute `terraform plan` and see what Terraform will create.

If you encounter an error like the one below, you need to give your user proper permissions. I will give `AmazonEC2FullAccess` in this article for now.  <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/28842869-9f38-404d-b9b5-8968ef2701bc" />
</p>

<br/>
 
After configuring the permission issue, you should see the plan after you execute the `terraform plan` command. The plan shows all the details about what Terraform will do once you execute `terraform apply`.  <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/9897e27e-3293-4ccf-85e7-3fb2e9ce01e3" />
</p>

<br/>
 
Let's execute `terraform apply` and create our EC2 instance and upload the `ecommerce.conf` file. It will ask you a question like 'Do you want to perform these actions?' when you execute the code, and you need to type `yes` if you want to move forward.
<br/>

> Keep in mind that if you want to run `terraform apply` without any confirmation, you should use the `-auto-approve` flag.


<br/>

You should see a similar result once you have finished executing the `terraform apply` command.  <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/7ce22dd9-c2cb-40ea-b285-4f0e10573f17" />
</p>

<br/>

We created our server and uploaded the configuration file. However, we should test our infrastructure and see the configuration file on the server.

<br/>

First, let's check to see if the EC2 instance is created or not. You should see a server named `EcommerceServer` in the instances list.

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/9f19665c-8b6d-4264-bbd8-eefb5d04d5e2" />
</p>

<br/>

If we are good with creating EC2 instances, let's go and check our configuration file. Now, we will try to connect to our EC2 instance. You need to give proper permissions again to your key pair file if you might run into the following error.

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/4e0e9c73-51a6-4b35-81ce-453dc5957a79" />
</p>

<br/>

You need to execute `chmod 400` and `ssh -i ./ProvisionerKeyPair.pem ec2-user@<Your EC2 Public IP>` respectively, and then you should see the result below.
<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/c2da5256-b1d3-43cb-a5ad-fa4f672103e6" />
</p>

<br/>

You can access your EC2 server and you should check your configuration file by typing the `dir` command. It will list all files in the directory.

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/58bd76f0-5117-4616-b2c9-f395acb65ec3" />
</p>

<br/>

Now, let's check if the file is correct or not by checking what is inside. You need to execute the `cat` command to see the content of the file.

<br/>

```
[ec2-user@ip-172-31-80-65 ~]$ cat ecommerce.conf
[database]
host = "database info"
port = 1234
username = firat
password = firat1234
```

<br/>

If you are done with checking the details, you can execute the `exit` command to return to the local machine.

<br/>

```
[ec2-user@ip-172-31-80-65 ~]$ exit
logout
Connection to 3.84.8.181 closed.
```

### Local-Exec Provisioner

`Local-exec` command is used to run commands on the local machine where Terraform is working. It is useful for informing users, running scripts, logging information, and so on during the processes. <br/>

> The important point is that you need to write `local-exec` in the resource definition block.

<br/>

The scenario will be the same, and we want to create an EC2 instance on AWS. We will store the public IP of the EC2 instance in a text file after creation is done. <br/>

Let's create the resource code and execute `terraform plan` and `terraform apply` respectively. <br/>

```
resource "aws_instance" "ecommerce_server" {
  ami           = data.aws_ami.linux.id
  instance_type = "t2.micro"
  key_name      = "ProvisionerKeyPair"

  vpc_security_group_ids = ["sg-00138b47ec51588d2"] # the security group that we just created
  associate_public_ip_address = true # SSH does not work without public IP. this line ensures that EC2 gets a public IP.

  provisioner "local-exec"{
    command = "echo ${self.public_ip} > instance_public_ip.txt"
  }

  tags = {
    Name = "EcommerceServer"
  }
}
```

<br/>

As you can see above, the resource code is almost the same. The only differences are that we removed the `file` provisioner implementation and wrote the local-exec implementation. However, you can implement both `file` and `local-exec` provisioners. <br/>
 
The final code should be like the one below. <br/>

```
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

  provisioner "local-exec"{
    command = "echo ${self.public_ip} > instance_public_ip.txt"
  }

  tags = {
    Name = "EcommerceServer"
  }
}
```

 <br/>

You should see your EC2 instance after you execute the commands. If you see the EC2 instance, you should see the `instance_public_ip.txt` file in the directory where **main.tf** is located in the `local-exec` provisioner. You will see the IP address when you check the details of the txt file. <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/f961d8bc-c457-4a35-8137-dfe078b37ee2" />
</p>

<br/>

### Remote-Exec Provisioner

`Remote-exec` provisioner is used to execute commands on a remote machine after your infrastructure has been created. <br/>

It is used to install software packages, configure services, run setup scripts, and so on. <br/>

> You have to specify the connection details such as WinRM for Windows or SSH for Linux instances. Terraform needs connection details to make communication with the remote resource.

<br/>

The scenario will be the same, and we want to create an EC2 instance. We will write "Hello from Terraform" into a text file after creation is done. <br/>

You can install the Apache server by following the codes, but you may face some additional costs. <br/>

```
sudo yum update -y # it updates the system packages
sudo yum install -y httpd # it installs Apache HTTP Server
sudo systemctl start httpd # it starts the Apache service
sudo systemctl enable httpd # it configures Apache to start on boot
```
<br/>

Let's create a resource code for the `EC2` instance and execute `terraform plan` and `terraform apply` respectively.

<br/>

```
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
    inline = [ 
        "echo 'Hello from Terraform!' > /home/ec2-user/testfile.txt"
     ]
  }

  tags = {
    Name = "EcommerceServer"
  }
}
```

<br/>

As you can see, we specify connection details like what we did for the file provisioner earlier and create a text `file` to store our message. <br/>

The final code should be like the one below. <br/>

```
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
```
<br/>

You should see the EC2 instance in the list on the AWS management console. <br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/e2a3ae01-6577-47fd-a040-dd209438f407" />
</p>

<br/>

If you execute the following command, you will connect to your EC2 instance that you just created. <br/>

```
ssh -i ProvisionerKeyPair.pem ec2-user@<Your EC2 Public IP>
```

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/c28d057e-963d-4c2c-9a3d-5b2bb0f414b0" />
</p>

<br/>

Let's check to see if our message is stored on the server or not. We need to use the `cat` command to see the details.

<br/>

```
cat /home/ec2-user/testfile.txt
```

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/6240cd0c-78b1-4efe-a2ca-23a64306d093" />
</p>

<br/>

### When Keyword

The `When` keyword is used to tell the provisioner when it should run. The keyword is for the `local-exec` provisioner and `remote-exec` provisioner. You cannot use it for the `file` provisioner. <br/>

Let's use the keyword and learn how to use it. `local-exec` will be used for it. You need to add the `when` keyword in the provisioner and decide when the provisioner should run. I will define `when = "destroy"` and execute the `terraform apply` command.
<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/1641502d-545d-4901-9a8e-4d37c4213f2d" />
</p>

<br/>

As you can see, the EC2 has been created but there is no text file in the directory. Let's destroy the EC2 using `terraform destroy` and see if the text file has been created or not.

<br/>

<p align="center">
   <img src="https://github.com/user-attachments/assets/c413c4c3-6c94-4920-8507-c9f1ca4082d8" />
</p>

<br/>

As you can see above, the text file has been created after the destroy process.<br/>

We checked on how to use Provider in Terraform with examples. You can use the details according to your needs or projects. If we summarize what we did:

1. If you want to upload a file, you need to use the `file` provisioner

2. If you want to execute a command on the local machine where Terraform is working, you need to use the `local-exec` provisioner

3. If you want to execute a command on a remote resource after the infrastructure has been created, you need to use the `remote-exec` provisioner

Since the article is for educational purposes, we should execute the `terraform destroy` command before we leave to avoid additional costs.

For more articles, <a href="https://www.firattonak.com" target="_blank">visit FiratTonak.com</a>

