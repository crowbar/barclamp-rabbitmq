name "rabbitmq-server_remove"
description "Deactivate RabbitMQ Server Role services"
run_list(
  "recipe[rabbitmq::deactivate_server]"
)
default_attributes()
override_attributes()
