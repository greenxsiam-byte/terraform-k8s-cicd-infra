# ---------- Find latest Ubuntu 22.04 AMI ----------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------- Server 1: Jenkins ----------
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_jenkins
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  user_data              = file("${path.module}/scripts/jenkins-install.sh")

  root_block_device {
    volume_size = 20
  }

  tags = { Name = "jenkins-server" }
}

# ---------- Server 2: Kubernetes control plane ----------
resource "aws_instance" "k8s_control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_control_plane
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  user_data              = file("${path.module}/scripts/k8s-common.sh")

  root_block_device {
    volume_size = 20
  }

  tags = { Name = "k8s-control-plane" }
}

# ---------- Server 3: Kubernetes worker node ----------
resource "aws_instance" "k8s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_worker
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  user_data              = file("${path.module}/scripts/k8s-common.sh")

  root_block_device {
    volume_size = 20
  }

  tags = { Name = "k8s-worker-node" }
}
