# ---------- Security group: Jenkins server ----------
# No SSH ingress, no Jenkins UI ingress — both are reached via AWS Session
# Manager (SSM): SSH via `aws ssm start-session`, the web UI via SSM port
# forwarding. No inbound port is open on this security group at all.
resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Outbound traffic only. SSH and Jenkins UI access are both via SSM."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}

# ---------- Security group: Kubernetes nodes (control plane + worker) ----------
# Self-managed kubeadm clusters need specific ports open between nodes.
# See: https://kubernetes.io/docs/reference/networking/ports-and-protocols/
# No SSH ingress here either — both nodes are reached via SSM.
resource "aws_security_group" "k8s" {
  name        = "k8s-sg"
  description = "Kubernetes control plane + worker node ports. SSH access is via SSM, not an open port."
  vpc_id      = aws_vpc.main.id

  # Kubernetes API server — only Jenkins (inside the subnet) needs this to run kubectl
  ingress {
    description = "Kubernetes API server, subnet only"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  # All traffic between nodes inside the subnet — covers etcd (2379-2380),
  # kubelet API (10250), kube-scheduler (10259), kube-controller-manager (10257),
  # NodePort services (30000-32767), and the CNI overlay network (Flannel/Calico).
  # AWS requires from_port/to_port = 0 when protocol = "-1" (all protocols) —
  # the port range is ignored entirely once all protocols are allowed.
  ingress {
    description = "All traffic between k8s nodes in the subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  # No public NodePort ingress rule — view the nginx page via SSM port
  # forwarding to the worker node instead. See the guide for the command.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "k8s-sg" }
}
