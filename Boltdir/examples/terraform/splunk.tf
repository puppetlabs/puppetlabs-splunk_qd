# GCP Project ID
variable "project"            { }
# Domain name assigned to DNS zone
variable "dns_domain"         { }
# Name of of the actual zone in GCP CloudDNS
variable "dns_zone"           { }
# Shared user name across instances
variable "user"               { }
# Password using for access to Windows through WinRM
variable "winrm_passwd"       { }
# Location on disk of the SSH key to use for Linux access
variable "ssh_key"            { default = "~/.ssh/id_rsa.pub" }
# GCP region for the deployment
variable "region"             { default = "us-west1" }
# GCP zone for the deployment
variable "zone"               { default = "us-west1-a" }
# Number of forwarders to deploy, number is actually doubled because it deploys both Linux AND Windows
variable "forwarder_count"    { default = 1 }
# The image deploy Linux from
variable "linux_image"        { default = "centos-cloud/centos-7" }
# The image deploy Windows from
variable "windows_image"      { default = "windows-cloud/windows-2019-core" }
# Permitted IP subnets, make this stricter and single IP adresses should be defined as a /32
variable "firewall_permitted" { default = [ "0.0.0.0/0" ] }
# A static ID for the deployment that can be used to group together multiple deployments of the test drive
variable "deployment_id"      { default = "0" }

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

# To contain each Splunk deployment, a fresh VPC to deploy into
resource "google_compute_network" "splunk" {
  name = "splunk-${var.deployment_id}"
  auto_create_subnetworks = false
}

# Manual creation of subnets works better when instances are dependent on their
# existance, allowing GCP to create them automatically creates a race condition.
resource "google_compute_subnetwork" "splunk_west" {
  name          = "splunk-${var.deployment_id}"
  ip_cidr_range = "10.138.0.0/20"
  network       = "${google_compute_network.splunk.self_link}"
}

# Instances should not be accessible by the open internet so a fresh VPC should
# be restricted to organization allowed subnets
resource "google_compute_firewall" "splunk_default" {
  name    = "splunk-default-${var.deployment_id}"
  network = "${google_compute_network.splunk.self_link}"
  priority = 1000
  source_ranges = var.firewall_permitted
  allow { protocol = "icmp" }
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
}

# Exception to the above, when provisioning SSL certificates from letsencrypt
# you must have at minimum port 80 open for domain validation, let then optimal
# but port 80 isn't used for any services and will be redirected to 443 if you
# try connecting to it
resource "google_compute_firewall" "splunk_ssl_validation" {
  name    = "splunk-ssl-validation-${var.deployment_id}"
  network = "${google_compute_network.splunk.self_link}"
  priority = 1001
  target_tags = [ "http-server" ]
  source_ranges = [ "0.0.0.0/0" ]
  allow {
    protocol = "tcp"
    ports = [ 80 ]
  }
}

# Create a friendly DNS name for accessing the new Splunk environment
resource "google_dns_record_set" "splunk" {
  name = "splunk-${var.deployment_id}.${var.dns_domain}."
  type = "A"
  ttl  = 1

  managed_zone = var.dns_zone

  rrdatas = ["${google_compute_instance.splunk.network_interface.0.access_config.0.nat_ip}"]
}

# An instance with a bit bigger disk for deploying Splunk Enterprise
resource "google_compute_instance" "splunk" {
  name         = "splunk-${var.deployment_id}"
  machine_type = "n1-standard-1"
  tags = [ "http-server" ]

  metadata = {
    "sshKeys" = "${var.user}:${file(var.ssh_key)}"
  }

  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 40
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.splunk.self_link
    subnetwork = google_compute_subnetwork.splunk_west.self_link
    access_config { }
  }

  # Using remote-execs on each instance deployemnt to ensure thing are really
  # really up before doing the next steps, helps with development tasks that
  # immediately attempt to leverage Bolt
  provisioner "remote-exec" {
    connection {
      host = self.network_interface[0].access_config[0].nat_ip
      type = "ssh"
      user = var.user
    }
    inline = ["# Connected"]
  }
}

# Small instances that are just good enough to generate some data
resource "google_compute_instance" "forwarder_linux" {
  count        = var.forwarder_count
  name         = "splunk-linux-vm-${var.deployment_id}-${count.index}"
  machine_type = "g1-small"

  metadata = {
    "sshKeys" = "${var.user}:${file(var.ssh_key)}"
  }

  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 15
      type = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.splunk.self_link
    subnetwork = google_compute_subnetwork.splunk_west.self_link
    access_config {}
  }

  provisioner "remote-exec" {
    connection {
      host = self.network_interface[0].access_config[0].nat_ip
      type = "ssh"
      user = var.user
    }
    inline = ["# Connected"]
  }
}

# Windows is such a resource hog even when using core
resource "google_compute_instance" "forwarder_windows" {
  count        = var.forwarder_count
  name         = "splunk-windows-vm-${var.deployment_id}-${count.index}"
  machine_type = "n1-standard-1"

  # No better way todo this on Windows in GCP
  metadata = {
    "sysprep-specialize-script-cmd" = <<SCRIPT
net user ${var.user} ${var.winrm_passwd} /add
net localgroup Administrators ${var.user} /add
SCRIPT
  }

  boot_disk {
    initialize_params {
      image = var.windows_image
      size  = 50
      type = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.splunk.self_link
    subnetwork = google_compute_subnetwork.splunk_west.self_link
    access_config {}
  }

  provisioner "remote-exec" {
    connection {
      host = self.network_interface[0].access_config[0].nat_ip
      type = "winrm"
      user = var.user
      password = var.winrm_passwd
      https = true
      insecure = true
      use_ntlm = true
    }
    inline = ["REM Connected"]
  }
}

# Convient log message at end of Terraform apply to inform you where your
# Splunk instance can be accessed.
output "fqdn" {
  value       = google_dns_record_set.splunk.name
  description = "The FQDN of a new Splunk Enterprise instance"
}
