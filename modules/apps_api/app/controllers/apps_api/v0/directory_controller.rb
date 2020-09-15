# frozen_string_literal: true

# dependencies
require_dependency 'apps_api/application_controller'

module AppsApi
  module V0
    class DirectoryController < ApplicationController
      skip_before_action(:authenticate)

      # When this endpoint is hit, it sends a request to Okta to return all applications on our organization,
      # and filters out any that contain an ISO date in their label
      def index
        redis = Redis.new
        # Check for existing cache of our app list
        filtered_apps = if redis.get('okta_directory_apps')
                          JSON.parse redis.get('okta_directory_apps')
                        else
                          Okta::DirectoryService.new.get_apps
                        end
        render json: {
          data: filtered_apps
        }
      end
    end
  end
end
