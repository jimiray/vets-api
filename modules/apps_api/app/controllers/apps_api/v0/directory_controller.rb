# frozen_string_literal: true

#dependencies
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
        if redis.get('okta_directory_apps')
          filtered_apps = JSON.parse redis.get('okta_directory_apps') 
          render json: {
            data: filtered_apps
          }
        else
          filtered_apps = Okta::DirectoryService.new.get_apps

          render json: {
            data: filtered_apps
          }

        end
      end

      def get_apps
          base_url = Settings.oidc.base_api_url + "/api/v1/apps?limit=200&filter=status+eq+\"ACTIVE\""
          unfiltered_apps = recursively_get_apps(okta_service, base_url)
          puts "Total apps before filtering: #{unfiltered_apps.length}"

          # matches any ISO date.
          iso_pattern = /(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d+)|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d)|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d)/
           
          # Iterate through the returned applications, and test for pattern matching, 
          # adding to our filtered apps array if pattern doesn't match
          filtered_apps = unfiltered_apps.select {|app| app["label"] !~ iso_pattern}
          puts "Total apps after filtering: #{filtered_apps.length}"

          redis.set('okta_directory_apps', filtered_apps.to_json)
          unfiltered_apps

      end

      def recursively_get_apps(okta_service, url="", unfiltered_apps=[])
        apps_response = okta_service.get_apps(url)
        # Moving apps in response body to iterable array
        unfiltered_apps.concat(apps_response.body)  

        # Check headers for ['link'] where 'rel' == next
        # If the next link exists, call okta_service.get_apps(next_link) and filter based on iso_pattern
        if contains_next(apps_response.headers)
          next_link = substring_next_link(apps_response.headers)
          recursively_get_apps(okta_service, next_link, unfiltered_apps)
        end

        unfiltered_apps
      end

      # Check if headers contains 'next' link, since 'next' is always after 'self', we can use .last as a consistent check
      def contains_next(headers)
        headers['link'].split(',').last.include?("next") 
      end

      def substring_next_link(headers)
        headers['link'].split(',').last.split("<").last.split(">").first
      end

      def get_scopes(apps)
        apps.each do |app|
         scopes = okta_service.get_app_scopes(app["id"])
         app["scopes"] = scopes
         puts scopes.body
        end
        apps
      end
    end
  end
end
