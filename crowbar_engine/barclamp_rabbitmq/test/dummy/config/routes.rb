Rails.application.routes.draw do

  mount BarclampRabbitmq::Engine => "/barclamp_rabbitmq"
end
