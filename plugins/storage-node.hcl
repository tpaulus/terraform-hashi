job "storage-node" {
  datacenters = ["seaview"]
  type        = "system"
  priority    = 100

  group "truenas-nfs-node" {
    task "node" {
      driver = "docker"

      env {
        CSI_NODE_ID = "${attr.unique.hostname}"
      }

      config {
        image = "democraticcsi/democratic-csi:v1.8.4"

        args = [
          "--csi-version=1.5.0",
          "--csi-name=org.democratic-csi.truenas-nfs",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=node",
          "--server-socket=/csi/csi.sock",
        ]

        # node plugins must run as privileged jobs because they
        # mount disks to the host
        privileged = true
        ipc_mode = "host"
        network_mode = "host"

        auth_soft_fail = true
      }

      csi_plugin {
        id        = "org.democratic-csi.truenas-nfs"
        type      = "node"
        mount_dir = "/csi"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
driver: freenas-api-nfs
instance_id:
httpConnection:
  protocol: https
  host: 10.0.10.32
  port: 443
  {{ with nomadVar "truenas" -}}
  apiKey: "{{ .apiKey }}"
  username: {{ .username }}
  {{- end }}
  allowInsecure: true
zfs:
  datasetParentName: tank/nomad/a/vols
  # do NOT make datasetParentName and detachedSnapshotsDatasetParentName overlap
  # they may be siblings, but neither should be nested in the other
  detachedSnapshotsDatasetParentName: tank/nomad/a/snaps
  datasetEnableQuotas: true
  datasetEnableReservation: false
  datasetPermissionsMode: "0777"
  datasetPermissionsUser: 0
  datasetPermissionsGroup: 0
nfs:
  shareHost: 10.0.10.32
  shareAlldirs: false
  shareAllowedHosts: []  # TODO Restrict this
  shareAllowedNetworks: []
  shareMaprootUser: root
  shareMaprootGroup: root
  shareMapallUser: ""
  shareMapallGroup: ""
EOH
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}