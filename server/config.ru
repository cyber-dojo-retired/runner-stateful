
require_relative './src/micro_service'
require 'prometheus/client'

warmup do |app|
  app.prom(Prometheus::Client.registry)
end

run MicroService
