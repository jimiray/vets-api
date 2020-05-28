# frozen_string_literal: true

require 'common/exceptions/base_error'
require 'common/exceptions/serializable_error'

module Common
  module Exceptions::Internal
    # Service Outage - Breakers is reporting an outage on a backend system
    class ServiceOutage < Common::Exceptions::BaseError
      def initialize(outage = nil, options = {})
        @outage = outage
        @detail = options[:detail] || i18n_field(:detail, service: @outage.service.name, since: @outage.start_time)
      end

      def errors
        Array(Common::Exceptions::SerializableError.new(i18n_data.merge(detail: @detail)))
      end
    end
  end
end
