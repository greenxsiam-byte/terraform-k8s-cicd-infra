# Terraform + Jenkins + Self-Managed Kubernetes CI/CD Pipeline

A complete, working CI/CD pipeline built on AWS:

- **Terraform** provisions 3 EC2 servers in a fresh VPC
- **Jenkins** runs on one server and deploys on every git push (via SCM polling)
- **Kubernetes** (self-managed via `kubeadm`, not EKS) runs across the other two servers
- **nginx** serves a static page, deployed and updated by Jenkins automatically
- **No SSH, no public web ports** — all access is via AWS Systems Manager (SSM)

This was built and debugged against a live AWS account in `ap-southeast-7`
(Bangkok). Every bug listed below actually happened and is fixed in this
version of the code.

## Architecture
git push
               |
               v
               +----------------------------+

|   Jenkins (EC2 server 1)   |  <- polls git every minute, runs kubectl

+----------------------------+

|

v

+----------------------------+      +----------------------------+

| k8s control plane (server 2)| <--> |  k8s worker (server 3)      |

|  kubeadm init, etcd, API    |      |  runs nginx pods             |

+----------------------------+      +----------------------------+

|

v

localhost:30080 (via SSM tunnel)

"Hello from Kubernetes!"

All three servers sit in one VPC/subnet with **zero inbound ports open**.
Access for shell, the Jenkins dashboard, and the nginx page is entirely
through `aws ssm start-session` — see `ACCESS.md` for exact commands.

## Setup order

1. `terraform init && terraform apply` — see variables in `variables.tf`,
   all have sensible defaults, no `-var` flags required
2. SSM into the control plane, run `kubeadm init`, install Flannel
3. SSM into the worker, run the `kubeadm join` command `kubeadm init` prints
4. SSM into Jenkins, copy the control plane's `~/.kube/config` to
   `/var/lib/jenkins/.kube/config`
5. Push this repo to your own GitHub/GitLab (private is fine)
6. In Jenkins: New Item → Pipeline → Pipeline script from SCM → point at
   your repo, credential = a GitHub PAT (classic, `repo` scope) added under
   Manage Jenkins → Credentials as "Username with password"
7. Build Now, then enable Build Triggers → Poll SCM (`* * * * *` for testing)

Full command-by-command detail is in `ACCESS.md`.

## Bugs hit and fixed during the real build

These are baked into the current scripts — listed here so a future rebuild
doesn't waste time rediscovering them:

| Bug | Fix applied |
|---|---|
| `t3.medium` not Free Tier eligible | `variables.tf` defaults to `t3.small`/`t3.micro` — **re-check your own account** with `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`, eligible types vary by account/region |
| Security group rejected `protocol = "-1"` with a port range | Fixed in `security_groups.tf`: AWS requires `from_port`/`to_port` = `0` when protocol is "all" |
| Jenkins install failed: `NO_PUBKEY`, repo not signed | Jenkins rotated its signing key. `scripts/jenkins-install.sh` now pulls `jenkins.io-2026.key` into `/etc/apt/keyrings/` — **if this breaks again in the future, check https://pkg.jenkins.io/debian-stable/ for the current key filename** |
| Jenkins installed but crash-looped on start (`exit-code 1`) | Jenkins LTS requires Java 21+; script now installs `openjdk-21-jdk` instead of 17 |
| `kubectl: command not found` on the Jenkins server | Caused by the GPG key failure above — everything after that line in the script never ran on the first boot. Fixed transitively once the GPG key issue was fixed; this would not recur on a fresh `terraform apply` |
| `kubeadm join` preflight errors (`already exists`, `port in use`) | Not a script bug — the join command was run on the control plane instead of the worker. Always confirm with `hostname` before running cluster commands over SSM, since multiple servers' shells look identical |
| `Permission denied` creating files over SSM | SSM's default working directory (`/var/snap/amazon-ssm-agent/...`) is root-owned. Always `cd ~` first in a new SSM session before writing files |
| GitHub `Password authentication is not supported` | Needed a **classic** PAT with `repo` scope, added in Jenkins as credential kind "Username with password" (not SSH key, not GitHub App) |
| `Unable to find Jenkinsfile` / manifest path errors | Files weren't actually present in the git repo yet — always verify on GitHub's web UI, don't assume a local `git push` succeeded |

## Files

- `versions.tf`, `variables.tf` — Terraform provider config and inputs
- `network.tf` — VPC, subnet, internet gateway, routing
- `security_groups.tf` — firewall rules (no SSH/web ports — SSM only)
- `iam.tf` — IAM role/instance profile granting SSM access
- `instances.tf`, `outputs.tf` — the 3 EC2 servers and their outputs
- `scripts/jenkins-install.sh` — boots Jenkins + Java 21 + kubectl
- `scripts/k8s-common.sh` — common kubeadm node prep (both control plane and worker)
- `Jenkinsfile` — the pipeline: checkout → validate → apply → verify rollout
- `k8s/nginx-deployment.yaml` — Deployment + ConfigMap + NodePort Service
- `ACCESS.md` — exact SSM commands for shell access and port forwarding
- `.gitignore` — excludes `.tfstate`, `.terraform/`, `.pem` keys, etc.

## Known limitations / next steps

- PAT-based git auth will need rotation before the token expires
- 3 EC2 instances running 24/7 costs money even at Free Tier sizes once
  Free Tier hours are exhausted — `terraform destroy` when not in use
- Poll SCM checks every minute by default in this guide; space this out
  (e.g. `H/5 * * * *`) for anything beyond short-term testing
- No HA: a single control plane node means cluster API downtime if that
  one instance has issues — fine for learning, not for production


  
