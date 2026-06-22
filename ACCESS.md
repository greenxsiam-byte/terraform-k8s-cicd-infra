# Connecting to the servers (no SSH, no public web ports)

This setup has zero inbound ports open for SSH, the Jenkins UI, or the nginx
NodePort. Everything goes through AWS Systems Manager (SSM), which only needs
an outbound connection from the instance to AWS — nothing for an attacker to
scan or hit from the internet.

Prerequisite: install the Session Manager plugin once on your machine —
see AWS's docs for "Install the Session Manager plugin for the AWS CLI."

After `terraform apply`, grab the instance IDs from the output:

```
jenkins_instance_id            = "i-0xxxxxxxxxxxxxxxx"
k8s_control_plane_instance_id  = "i-0xxxxxxxxxxxxxxxx"
k8s_worker_instance_id         = "i-0xxxxxxxxxxxxxxxx"
```

## Shell access (replaces SSH)

```powershell
aws ssm start-session --target <instance_id>
```

This drops you into a bash shell on the instance — use it for the `kubeadm
init`, `kubeadm join`, and Jenkins setup steps from the main guide exactly as
written.

## Viewing the Jenkins dashboard (replaces opening port 8080)

Run this from PowerShell — it stays running and holds the tunnel open:

```powershell
aws ssm start-session `
  --target <jenkins_instance_id> `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
```

Leave that window open, then visit `http://localhost:8080` in your browser.
Closing the PowerShell window ends the tunnel.

## Viewing the nginx page (replaces opening NodePort 30080)

Same idea, targeting the worker node:

```powershell
aws ssm start-session `
  --target <k8s_worker_instance_id> `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["30080"],"localPortNumber":["30080"]}'
```

Then visit `http://localhost:30080`.

## Why this is better than an IP allowlist

An IP allowlist (`cidr_blocks = [var.my_ip]`) still leaves a port open to the
internet — it just filters who's let through, and breaks the moment your IP
changes. SSM port forwarding opens no port at all. The connection is
initiated outbound by your AWS CLI, authenticated by your AWS IAM
credentials (not your network location), and torn down when you close the
session. Your home/mobile IP changing has no effect on this.
