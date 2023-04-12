job "obs-graphite-exporter" {
  datacenters = ["seaview"]
  type = "service"

  group "prometheus_graphite_exporter" {
    count = 1

    task "prometheus_graphite_exporter" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "prom/graphite-exporter:v0.13.3"
        args = ["--graphite.listen-address=0.0.0.0:2003", "--graphite.mapping-config=local/graphite_mapping.conf"]
      }

      resources {
        cpu    = 256
        memory = 64
      }

      service {
        name     = "prometheus-graphite-exporter"
        provider = "consul"
        port     = 9108
        tags     = ["global", "metrics", "metrics-scraper"]
        address_mode = "driver"
        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "30s"
          address_mode = "driver"
        }
      }
      
      template {
        data = <<EOH
---
# All FreeNAS metrics start with server.<server_name>
# https://www.truenas.com/community/threads/mapping-of-freenas-data-sent-to-graphite_exporter-part-of-prometheus.80948/
# https://blog.bradbeattie.com/freenas-to-prometheus/

# Validate configuration with:
# /path/to/graphite_exporter --check-config --graphite.mapping-config=/path/to/this_file.yml
# graphite_exporter --check-config --graphite.mapping-config=files/configs/present/graphite_mapping-2.yml

# To develop mappings locally:
# graphite_exporter --log.level=debug --graphite.mapping-config=
# nc localhost 9109 < graphite-sample.txt
# curl localhost:9108/metrics -s | grep ^freenas | less

# Mapping syntax is based on statsd_exporter.
# https://github.com/prometheus/statsd_exporter#regular-expression-matching

mappings:

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.disktemp-(.*)\.temperature'
    match_type: regex
    name: "freenas_disk_temperature"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      disk: '${5}'

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.cputemp-(.*)\.temperature'
    match_type: regex
    name: "freenas_cpu_temperature"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      cpu: '${5}'

  # When "Report CPU usage in percent" is NOT selected. (default)
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.aggregation_cpu_(.*)\.percent-(.*)'
    match_type: regex
    name: "freenas_cpu_percent_${5}"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      mode: '${6}'

  # When "Report CPU usage in percent" is selected.
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.aggregation_cpu_(.*)\.cpu-(.*)'
    match_type: regex
    name: "freenas_cpu_usage_${5}"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      mode: '${6}'

  # When "Report CPU usage in percent" is NOT selected. (default)
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.cpu-(.*)\.cpu-(.*)'
    match_type: regex
    name: "freenas_cpu_usage"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      cpu: '${5}'
      mode: '${6}'

  # When "Report CPU usage in percent" is selected.
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.cpu-(.*)\.percent-(.*)'
    match_type: regex
    name: "freenas_cpu_percent"
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      cpu: '${5}'
      mode: '${6}'

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.df-(.*)\.df_complex-(.*)'
    match_type: regex
    name: 'freenas_df_${6}'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      filesystem: '${5}'

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.disk-(.*)\.disk_(.*)\.(.*)'
    match_type: regex
    name: 'freenas_disk_${6}_${7}'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      device: '${5}'

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.interface-(.*)\.if_(.*)\.(.*)'
    match_type: regex
    name: 'freenas_interface_${7}_${6}'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
      interface: '${5}'

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.load\.load\.longterm'
    match_type: regex
    name: 'freenas_load_15'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.load\.load\.midterm'
    match_type: regex
    name: 'freenas_load_5'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite
  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.load\.load\.shortterm'
    match_type: regex
    name: 'freenas_load_1'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.memory\.memory-(.*)'
    match_type: regex
    name: 'freenas_memory_${5}'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.swap\.swap-(.*)'
    match_type: regex
    name: 'freenas_swap_${5}'
    labels:
      instance: '${1}.${2}.${3}.${4}'
      job: freenas-graphite

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.uptime\.uptime'
    match_type: regex
    name: freenas_uptime
    labels:
      job: freenas-graphite
      instance: "${1}.${2}.${3}.${4}"

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.processes\.ps_state-(.*)'
    match_type: regex
    name: freenas_processes
    labels:
      job: freenas-graphite
      instance: "${1}.${2}.${3}.${4}"
      state: "${5}"

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.([^.]*)\.([^.]*)$'
    match_type: regex
    name: freenas_graphite_${5}
    labels:
      job: freenas-graphite-raw
      instance: "${1}.${2}.${3}.${4}"
      item: "${6}"

  - match: 'servers\.([^_]*)_([^_]*)_([^_]*)_([^_]*)\.(.*)'
    match_type: regex
    name: freenas_graphite_raw
    labels:
      job: freenas-graphite-raw
      instance: "${1}.${2}.${3}.${4}"
      graphite_metric: "${5}"

  - match: 'sensor.*.*'
    name: sensor_${5}
    labels:
      job: esp32-sensors
      instance: ${1}.${2}.${3}.${4}

        EOH
        
        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/graphite_mapping.conf"
      }
    }
  }
}

