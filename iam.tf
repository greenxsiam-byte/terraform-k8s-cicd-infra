# IAM role that lets EC2 instances be reached via AWS Systems Manager (SSM)
# Session Manager — this replaces SSH entirely, so no port 22 needs to be open
# and no .pem key needs to be managed. Connect with:
#   aws ssm start-session --target <instance-id>

resource "aws_iam_role" "ec2_ssm" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# AWS-managed policy that grants the permissions SSM's agent needs
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile is the wrapper that actually attaches an IAM role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}
