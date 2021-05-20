# frozen_string_literal: true

module Mobile
  class ServiceGraph
    attr_accessor :services
    
    def initialize
      @services = {}
    end
    
    def add_service(service)
      @services[service.name] = service
    end
    
    def link_service(upstream_name, downstream_name)
      raise "could not find upstream service '#{upstream_name}'" unless @services[upstream_name]
      raise "could not find downstream service '#{downstream_name}'" unless @services[downstream_name]
      @services[upstream_name].add_service(@services[downstream_name])
    end
    
    def [](name)
      @services[name]
    end
    
    def downstream_services_from(name)
      queue = []
      queue.push(@services[name])
      downstream_services = []
      
      while queue.size != 0
        s = queue.shift
        downstream_services.push(s.name) if s && s.name != name && s.part_of_api
        s.dependent_services.each do |ds|
          queue.push(ds)
        end
      end
      
      downstream_services
    end
  end
end
