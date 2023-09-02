resource "nomad_csi_volume" "n8n_volume" {
  lifecycle {
    prevent_destroy = true
  }

  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "n8n_volume"
  name         = "n8n_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "blog_volume" {
  lifecycle {
    prevent_destroy = true
  }

  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "blog_volume"
  name         = "blog_volume"
  capacity_min = "1GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "blog_db_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "blog_db_volume"
  name         = "blog_db_volume"
  capacity_min = "1GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "netbox_db_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "netbox_db_volume"
  name         = "netbox_db_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "netbox_media_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "netbox_media_volume"
  name         = "netbox_media_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "home_assistant_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "home_assistant_volume"
  name         = "home_assistant_volume"
  capacity_min = "10GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "unifi_protect_backup_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "unifi_protect_backup_volume"
  name         = "unifi_protect_backup_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "grafana_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "grafana_volume"
  name         = "grafana_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "prometheus_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "prometheus_volume"
  name         = "prometheus_volume"
  capacity_min = "10GiB"
  capacity_max = "100GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "icloud_pd_volume" {
  lifecycle {
    prevent_destroy = true
  }
  
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "icloud_pd_volume"
  name         = "icloud_pd_volume"
  capacity_min = "500GiB"
  capacity_max = "500GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_csi_volume" "restic_volume" {
  lifecycle {
    prevent_destroy = true
  }

  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "restic_volume"
  name         = "restic_volume"
  capacity_min = "500GiB"
  capacity_max = "500GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}