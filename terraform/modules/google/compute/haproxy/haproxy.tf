#--------------------------------------------------------------
# This module creates all resources necessary for HAProxy
#--------------------------------------------------------------

variable "name"              { }
variable "zones" {
  type = "list"
}
variable "atlas_username"    { }
variable "atlas_environment" { }
variable "atlas_token"       { }
variable "private_subnet_names"              { 
  type = "list"
}
variable "image" {}
variable "nodes"             { }
variable "instance_type"     { }

data "template_file" "haproxy_config" {
  template = "${file("${path.module}/haproxy.sh.tpl")}"
  count    = "${var.nodes}"

  vars {
    atlas_username    = "${var.atlas_username}"
    atlas_environment = "${var.atlas_environment}"
    atlas_token       = "${var.atlas_token}"
    node_name         = "${var.name}-${count.index}"
  }
}

resource "google_compute_instance" "haproxy" {
  name         = "${var.name}-${count.index}"
  count        = "${var.nodes}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, count.index)}"

  metadata_startup_script = "${element(data.template_file.haproxy_config.*.rendered, count.index)}"

  disk {
    image = "${var.image}"
  }

  network_interface {
    subnetwork = "${element(var.private_subnet_names, count.index)}"

    access_config {
      # ephemeral
    }
  }

  tags = ["haproxy"]

}

output "private_ips" {
  value = ["${google_compute_instance.haproxy.*.network_interface.0.address}"]
}
