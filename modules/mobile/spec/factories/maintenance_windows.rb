# frozen_string_literal: true

FactoryBot.define do
  factory :mobile_maintenance_window, class: '::MaintenanceWindow' do
    pagerduty_id { 'PHQI9WA' }
    external_service { 'evss' }
    start_time { '2021-05-25 22:33:39' }
    end_time { '2021-05-26 00:33:39' }
    description { 'MyString' }
  end
end
