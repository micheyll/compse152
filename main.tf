resource "openstack_compute_keypair_v2" "my-cloud-key" {
  name = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "openstack_compute_instance_v2" "vm-main" {
  name            = "vm-main"
  image_name      = "Ubuntu-24.04"
  flavor_name     = "standard.tiny"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = [openstack_networking_secgroup_v2.secgroup_1.name]

  network {
    name = "project_2011612"
  }
}

resource "openstack_compute_instance_v2" "vm-other" {
  name            = "vm-${count.index}"
  image_name      = "ubuntu-24.04"
  flavor_name     = "standard.tiny"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = [openstack_networking_secgroup_v2.secgroup_2.name]
  count           = 3

  network {
    name = "project_2011612"
  }
}

# Create floating IP
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "public"
}

# Associate floating IP with vm-main
resource "openstack_compute_floatingip_associate_v2" "fip_association_1" {
  floating_ip = openstack_networking_floatingip_v2.fip_1.address
  instance_id = openstack_compute_instance_v2.vm-main.id
}

# First security group for vm-main with public internet access
resource "openstack_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_vm1"
  description = "Security group for VM1 with SSH, HTTP and internal access"
}

# Single rule to allow all ingress traffic from project network
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1_all" {
  direction         = "ingress"
  ethertype        = "IPv4"
  remote_ip_prefix = "192.168.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

# Rules for the vm-main security group
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1_ssh" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1_http" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 80
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1_internal" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_ip_prefix = "192.168.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

# Second security group for vm-2-4 with internal network access only
resource "openstack_networking_secgroup_v2" "secgroup_2" {
  name        = "secgroup_internal"
  description = "Security group for internal VMs with project network access only"
}

# Single rule to allow all ingress traffic from project network
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2_all" {
  direction         = "ingress"
  ethertype        = "IPv4"
  remote_ip_prefix = "192.168.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_2.id
}
