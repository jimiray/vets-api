# frozen_string_literal: true

require 'google/apis/analyticsreporting_v4'

module CypressViewportUpdater
  class GoogleAnalyticsReports
    include Google::Apis::AnalyticsreportingV4
    include Google::Auth

    data = YAML.safe_load(File.open('config/settings.local.yml'))
    JSON_CREDENTIALS = data['google_analytics_service_credentials'].to_json
    SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'
    VIEW_ID = '176188361'

    attr_reader :analytics

    def initialize
      @analytics = AnalyticsReportingService.new
      analytics.authorization = ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(JSON_CREDENTIALS),
        scope: SCOPE
      )
    end

    def request_reports
      request = GetReportsRequest.new(report_requests: [
                                        user_report_request,
                                        viewport_report_request
                                      ])
      analytics.batch_get_reports(request).reports
    end

    private

    def user_report_request
      ReportRequest.new(
        view_id: VIEW_ID,
        date_ranges: [date_range],
        metrics: [metric_user]
      )
    end

    def viewport_report_request
      ReportRequest.new(
        view_id: VIEW_ID,
        date_ranges: [date_range],
        metrics: [metric_user],
        dimensions: [dimension_device_category, dimension_screen_resolution],
        order_bys: [{ field_name: 'ga:users', sort_order: 'DESCENDING' }],
        page_size: 100
      )
    end

    def date_range
      start_date = CypressViewportUpdater::UpdateCypressViewportsJob::START_DATE
      end_date = CypressViewportUpdater::UpdateCypressViewportsJob::END_DATE
      DateRange.new(start_date: start_date, end_date: end_date)
    end

    def metric_user
      Metric.new(expression: 'ga:users')
    end

    def dimension_device_category
      Dimension.new(name: 'ga:deviceCategory')
    end

    def dimension_screen_resolution
      Dimension.new(name: 'ga:screenResolution')
    end
  end
end