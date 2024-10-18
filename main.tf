provider "aws" {
  region = "ap-south-1"
}

# Variables
variable "AnsibleAMI" {
  description = "AMI for Ansible Controller and Node1"
  default     = "ami-0522ab6e1ddcc7055"  # Replace with a valid AMI ID for your region
}

variable "InstanceType" {
  description = "Instance type for Ansible Controller and Node1"
  default     = "t2.micro"
}

variable "KeyPair" {
  description = "SSH Key Pair"
  default     = "devops"
}

variable "SecurityGroupID" {
  description = "The ID of the existing security group to associate with the instances"
  default     = "sg-0a4b86efefd9999b7"  # Your existing security group ID
}

variable "User" {
  description = "The default user for SSH access"
  default     = "ubuntu"
}

# Ansible Controller
resource "aws_instance" "ansible_controller" {
  ami                    = var.AnsibleAMI
  instance_type          = var.InstanceType
  key_name               = var.KeyPair
  vpc_security_group_ids = [var.SecurityGroupID]

  tags = {
    Name = "AnsibleController"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y ansible
    sudo apt install -y python3-pip
    pip3 install boto boto3

    # Generate SSH key on controller
    ssh-keygen -t rsa -N "" -f /home/ubuntu/.ssh/id_rsa
    chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa /home/ubuntu/.ssh/id_rsa.pub
  EOF

  provisioner "local-exec" {
    command = "echo 'Ansible Controller created and ready'"
  }
}

# Ansible Node1
resource "aws_instance" "ansible_node1" {
  ami                    = var.AnsibleAMI
  instance_type          = var.InstanceType
  key_name               = var.KeyPair
  vpc_security_group_ids = [var.SecurityGroupID]

  depends_on = [aws_instance.ansible_controller]  # Ensure Controller is created first

  tags = {
    Name = "AnsibleNode1"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo mkdir -p /home/ubuntu/.ssh
    sudo chmod 700 /home/ubuntu/.ssh
  EOF

  provisioner "local-exec" {
    command = "echo 'Ansible Node1 created, waiting for 60 seconds...'; sleep 60"
  }

  # SSH Setup Between Ansible Controller and Node1
  provisioner "remote-exec" {
    inline = [
      "echo 'Passwordless SSH setup between Controller and Node1 completed'",
      "scp -o StrictHostKeyChecking=no -i /etc/ansible/devops.pem ubuntu@${aws_instance.ansible_controller.public_ip}:/home/ubuntu/.ssh/id_rsa.pub /home/ubuntu/.ssh/authorized_keys",
      "sudo chmod 600 /home/ubuntu/.ssh/authorized_keys",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys"
    ]

    connection {
      type        = "ssh"
      user        = var.User
      private_key = file("/etc/ansible/devops.pem")
      host        = aws_instance.ansible_node1.public_ip
    }
  }

  # Test passwordless SSH connection from controller to node1
  provisioner "remote-exec" {
    inline = [
      "echo 'Testing SSH connection from controller to node1'",
      "ssh -o StrictHostKeyChecking=no -i /etc/ansible/devops.pem ubuntu@${aws_instance.ansible_node1.public_ip} 'echo SSH connection successful'"
    ]

    connection {
      type        = "ssh"
      user        = var.User
      private_key = file("/etc/ansible/devops.pem")
      host        = aws_instance.ansible_node1.public_ip
    }
  }
}

# Outputs
output "ansible_controller_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}

output "ansible_node1_public_ip" {
  value = aws_instance.ansible_node1.public_ip
}
