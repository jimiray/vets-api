# frozen_string_literal: true

require 'backend_services'

module Swagger
  module Requests
    class FeatureToggles
      include Swagger::Blocks

      swagger_path '/v0/feature_toggles' do
        operation :get do
          key :description, 'Gets the current status of feature toggles'
          key :operationId, 'getFeatureToggless'
          key :tags, %w[site]

          parameter :optional_authorization
          parameter :features

          parameter do
            key :name, :cookie_id
            key :in, :query
            key :description, 'a unique string from the front end so that features can be configured to be "sticky" for
                               unauthenticated users'
            key :required, false
            key :type, :string
          end

          response 200 do
            key :description, 'Response is OK'
            schema do
              key :required, %i[data]
              property :data, type: :object do
                key :required, %i[features]
                property :features, type: :array do
                  items do
                    property :name, type: :string, example: 'facility_locator'
                    property :value, type: :boolean
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
