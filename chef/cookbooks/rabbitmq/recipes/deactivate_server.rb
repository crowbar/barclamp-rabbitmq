unless node['roles'].include?('rabbitmq-server')
  node["rabbitmq"]["services"]["server"].each do |name|
    service name do
      action [:stop, :disable]
    end
  end
  node.delete('rabbitmq')
  node.save
end
