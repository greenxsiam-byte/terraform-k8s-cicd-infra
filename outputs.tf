output "jenkins_instance_id" {
  description = "Instance ID — use with: aws ssm start-session --target <this-id>"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins server — Jenkins UI at http://<this-ip>:8080"
  value       = aws_instance.jenkins.public_ip
}

output "k8s_control_plane_instance_id" {
  description = "Instance ID — use with: aws ssm start-session --target <this-id>"
  value       = aws_instance.k8s_control_plane.id
}

output "k8s_control_plane_public_ip" {
  description = "Public IP of the Kubernetes control plane node"
  value       = aws_instance.k8s_control_plane.public_ip
}

output "k8s_control_plane_private_ip" {
  description = "Private IP of the control plane — used by the worker node to join"
  value       = aws_instance.k8s_control_plane.private_ip
}

output "k8s_worker_instance_id" {
  description = "Instance ID — use with: aws ssm start-session --target <this-id>"
  value       = aws_instance.k8s_worker.id
}

output "k8s_worker_public_ip" {
  description = "Public IP of the Kubernetes worker node"
  value       = aws_instance.k8s_worker.public_ip
}
