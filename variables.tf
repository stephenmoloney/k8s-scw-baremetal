variable "ubuntu_version_long_name" {
  type = "string"
  default = "Ubuntu Bionic"
}

variable "ubuntu_version_short_name" {
  type = "string"
  default = "bionic"
}

variable "docker_version" {
  default     = "18.06"
  description = "Can be non-specific (eg 18.06) or exact (eg 18.06.0~ce~3-0~ubuntu)"
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
  default     = "armv7l mainline 4.4.127"
  description = "Use `armv7l mainline 4.4.127` for arm and `x86_64 mainline 4.9.93` for amd"
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
