# frozen_string_literal: true

module Mobile
  class ServiceNode
    attr_accessor :part_of_api, :name, :dependent_services
    
    def initialize(name:, part_of_api: false)
      @name = name
      @part_of_api = part_of_api
      @dependent_services = []
    end
    
    def add_service(service)
      @dependent_services << service
    end
  end
end
