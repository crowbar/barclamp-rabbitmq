case node["platform"]
when "suse"
  default["rabbitmq"]["services"] = {
    "server" => ["rabbitmq-server"]
  }
end
