# frozen_string_literal: true

module Mobile
  class ServiceGraph
    attr_accessor :services

    def initialize(*graph)
      @services = {}

      graph.each do |service|
        upstream = service.first
        downstream = service.last
        @services[upstream] = Mobile::ServiceNode.new(name: upstream) unless @services[upstream]
        @services[downstream] = Mobile::ServiceNode.new(name: downstream) unless @services[downstream]
        link_service(upstream, downstream)
      end
    end

    def [](name)
      @services[name]
    end

    def affected_services(name)
      queue = []
      queue.push(@services[name])
      downstream_services = []

      while queue.size != 0
        s = queue.shift
        downstream_services.push(s.name) if s && s.name != name && s.leaf?
        s.dependent_services.each do |ds|
          queue.push(ds)
        end
      end

      downstream_services
    end

    private

    def link_service(upstream_name, downstream_name)
      raise "could not find upstream service '#{upstream_name}'" unless @services[upstream_name]
      raise "could not find downstream service '#{downstream_name}'" unless @services[downstream_name]

      @services[upstream_name].add_service(@services[downstream_name])
    end
  end
end
