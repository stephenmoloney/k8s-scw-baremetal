variable "ubuntu_version" {
  default = "Ubuntu Xenial"
  description = <<EOT
Use Ubuntu Xenial for arm, Ubuntu Bionic Beaver or Ubuntu Xenial
for amd64. Kubernetes only has xenial packages.
EOT
  description = ""
}

variable "docker_version" {
  default     = "17.03.0~ce-0~ubuntu-xenial"
  description = "Can be non-specific with 5 characters (eg 18.06) or exact (eg 18.06.0~ce~3-0~ubuntu)"
}

variable "k8s_version" {
  default = "stable-1.11"
}

variable "weave_passwd" {
  default = "ChangeMe"
}

variable "arch" {
  default     = "arm"
  description = "Values: arm arm64 x86_64"
}

variable "arch_bootscript" {
  default     = "4.4.127"
  description = <<EOT
Specify the kernel and bootscript image to use.
Use `4.4.127` for arm on ubuntu xenial
Use `4.4.127` or `4.9.93` for arm on ubuntu bionic beaver
Use `4.4.127` or `4.9.93` for arm on amd64
To view possible kernels, run command such as:
curl -sH "X-Auth-Token: $SCALEWAY_TOKEN" -H 'Content-Type: application/json' https://cp-par1.scaleway.com/images/ | \
jq '.[][] | select ( .arch == "arm" ) | select ( .name == "Ubuntu Bionic Beaver" )' | jq .default_bootscript.title
EOT
}

variable "region" {
  default     = "par1"
  description = "Values: par1 ams1"
}

variable "server_type" {
  default     = "C1"
  description = "Use C1 for arm, ARM64-2GB for arm64 and C2S for x86_64"
}

variable "server_type_node" {
  default     = "C1"
  description = "Use C1 for arm, ARM64-2GB for arm64 and C2S for x86_64"
}

variable "nodes" {
  default = 2
}

variable "ip_admin" {
  type        = "list"
  default     = ["0.0.0.0/0"]
  description = "IP access to services"
}

variable "private_key" {
  type        = "string"
  default     = "~/.ssh/id_rsa"
  description = "The path to your private key"
}
