#
# Cookbook Name:: rabbitmq
# Recipe:: rabbit
#
# Copyright 2010, Opscode, Inc.
# Copyright 2011, Dell, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ha_enabled = node[:rabbitmq][:ha][:enabled]

node[:rabbitmq][:address] = CrowbarRabbitmqHelper.get_listen_address(node)
node[:rabbitmq][:mochiweb_address] = node[:rabbitmq][:address]
node[:rabbitmq][:addresses] = [ node[:rabbitmq][:address] ]
node[:rabbitmq][:addresses] << CrowbarRabbitmqHelper.get_public_listen_address(node) if node[:rabbitmq][:listen_public]

if ha_enabled
  node[:rabbitmq][:nodename] = "rabbit@#{CrowbarRabbitmqHelper.get_ha_vhostname(node)}"
end

include_recipe "rabbitmq::default"

rabbitmq_status = true

if ha_enabled
  log "HA support for rabbitmq is enabled"
  include_recipe "rabbitmq::ha"
  # All the rabbitmqctl commands are local, and can only be run if rabbitmq is
  # local
  service_name = "rabbitmq"
  check_cmd = Mixlib::ShellOut.new("crm resource show #{service_name} | grep \" #{node.hostname} *$\"")
  rabbitmq_status = false if check_cmd.run_command.stdout.empty?
else
  log "HA support for rabbitmq is disabled"
end

# remove guest user
rabbitmq_user "remove guest user" do
  user "guest"
  action :delete
  only_if { rabbitmq_status }
end

# add a vhost to the queue
rabbitmq_vhost node[:rabbitmq][:vhost] do
  action :add
  only_if { rabbitmq_status }
end

# create user for the queue
rabbitmq_user "adding user #{node[:rabbitmq][:user]}" do
  user node[:rabbitmq][:user]
  password node[:rabbitmq][:password]
  address node[:rabbitmq][:mochiweb_address]
  port node[:rabbitmq][:mochiweb_port]
  action :add
  only_if { rabbitmq_status }
end

# grant the user created above the ability to do anything with the vhost
# the three regex's map to config, write, read permissions respectively
rabbitmq_user "setting permissions for #{node[:rabbitmq][:user]}" do
  user node[:rabbitmq][:user]
  vhost node[:rabbitmq][:vhost]
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
  only_if { rabbitmq_status }
end

execute "rabbitmqctl set_user_tags #{node[:rabbitmq][:user]} management" do
  not_if "rabbitmqctl list_users | grep #{node[:rabbitmq][:user]} | grep -q management"
  action :run
  only_if { rabbitmq_status }
end

if node[:rabbitmq][:trove][:enabled]
  rabbitmq_vhost node[:rabbitmq][:trove][:vhost] do
    action :add
    only_if { rabbitmq_status }
  end

  rabbitmq_user "adding user #{node[:rabbitmq][:trove][:user]}" do
    user node[:rabbitmq][:trove][:user]
    password node[:rabbitmq][:trove][:password]
    address node[:rabbitmq][:mochiweb_address]
    port node[:rabbitmq][:mochiweb_port]
    action :add
    only_if { rabbitmq_status }
  end

  # grant the trove user the ability to do anything with the trove vhost
  # the three regex's map to config, write, read permissions respectively
  rabbitmq_user "setting permissions for #{node[:rabbitmq][:trove][:user]}" do
    user node[:rabbitmq][:trove][:user]
    vhost node[:rabbitmq][:trove][:vhost]
    permissions "\".*\" \".*\" \".*\""
    action :set_permissions
    only_if { rabbitmq_status }
  end
else
  rabbitmq_user "deleting user #{node[:rabbitmq][:trove][:user]}" do
    user node[:rabbitmq][:trove][:user]
    address node[:rabbitmq][:mochiweb_address]
    port node[:rabbitmq][:mochiweb_port]
    action :delete
    only_if { rabbitmq_status }
  end

  rabbitmq_vhost node[:rabbitmq][:trove][:vhost] do
    action :delete
    only_if { rabbitmq_status }
  end
end

# save data so it can be found by search
node.save
