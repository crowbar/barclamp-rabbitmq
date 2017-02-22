unless node['roles'].include?('rabbitmq-server')
  # HA part if node is in a cluster
  if File.exist?("/usr/sbin/crm")
    vhostname = CrowbarRabbitmqHelper.get_ha_vhostname(node)
    drbd_resource = "rabbitmq"

    vip_primitive = "vip-admin-#{vhostname}"
    service_name = "rabbitmq"
    fs_primitive = "fs-#{service_name}"
    drbd_primitive = "drbd-#{drbd_resource}"
    ms_name = "ms-#{drbd_primitive}"
    group_name = "g-#{service_name}"

    pacemaker_group group_name do
      action [:stop, :delete]
      only_if "crm configure show #{group_name}"
    end
    pacemaker_primitive service_name do
      action [:stop, :delete]
      only_if "crm configure show #{service_name}"
    end
    pacemaker_primitive vip_primitive do
      action [:stop, :delete]
      only_if "crm configure show #{vip_primitive}"
    end
    pacemaker_primitive fs_primitive do
      action [:stop, :delete]
      only_if "crm configure show #{fs_primitive}"
    end
    if node[:rabbitmq][:ha][:storage][:mode] == "drbd"
      pacemaker_order "o-#{service_name}" do
        action [:stop, :delete]
        only_if "crm configure show o-#{service_name}"
      end
      pacemaker_colocation "col-#{service_name}" do
        action [:stop, :delete]
        only_if "crm configure show col-#{service_name}"
      end
      pacemaker_order "o-#{fs_primitive}" do
        action [:stop, :delete]
        only_if "crm configure show o-#{fs_primitive}"
      end
      pacemaker_colocation "col-#{fs_primitive}" do
        action [:stop, :delete]
        only_if "crm configure show #{fs_primitive}"
      end
      pacemaker_ms ms_name do
        action [:stop, :delete]
        only_if "crm configure show #{ms_name}"
      end
      pacemaker_primitive drbd_primitive do
        action [:stop, :delete]
        only_if "crm configure show #{drbd_primitive}"
      end
    end
  end

  # Non HA part if service is on a standalone node
  node["rabbitmq"]["services"]["server"].each do |name|
    service name do
      action [:stop, :disable]
    end
  end
  node.delete('rabbitmq')

  node.save
end
