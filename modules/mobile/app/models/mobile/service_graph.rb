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

    def affected_services(windows)
      downstream_services = {}

      windows.each do |window|
        name = window.external_service.to_sym
        queue = []
        queue.push(@services[name])

        while queue.size != 0
          s = queue.shift
          if s && s.name != name && s.leaf?
            downstream_services[s.name] =
              create_or_update_window(downstream_services[s.name], s.name, window)
          end
          s.dependent_services.each do |ds|
            queue.push(ds)
          end
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

    def create_or_update_window(service, downstream_name, window)
      if service
        start_time = [service.start_time, window.start_time].min
        end_time = [service.end_time, window.end_time].max
        description = service.description + ", #{window.description}"
      else
        start_time = window.start_time
        end_time = window.end_time
        description = window.description
      end

      Mobile::MaintenanceWindow.new(
        external_service: downstream_name,
        start_time: start_time,
        end_time: end_time,
        description: description
      )
    end
  end
end
