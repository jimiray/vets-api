# frozen_string_literal: true

require 'json_marshal/marshaller'
require 'common/exceptions'

module AppealsApi
  class HigherLevelReview < ApplicationRecord
    include HlrStatus
    include HlrFieldsFormattable

    def self.past?(date)
      date < Time.zone.today
    end

    def self.date_from_string(string)
      string.match(/\d{4}-\d{2}-\d{2}/) && Date.parse(string)
    rescue ArgumentError
      nil
    end

    attr_encrypted(:form_data, key: Settings.db_encryption_key, marshal: true, marshaler: JsonMarshal::Marshaller)
    attr_encrypted(:auth_headers, key: Settings.db_encryption_key, marshal: true, marshaler: JsonMarshal::Marshaller)

    NO_ADDRESS_PROVIDED_SENTENCE = 'USE ADDRESS ON FILE'
    NO_EMAIL_PROVIDED_SENTENCE = 'USE EMAIL ON FILE'
    NO_PHONE_PROVIDED_SENTENCE = 'USE PHONE ON FILE'

    validate :custom_validation, if: proc { |a| a.form_data.present? }

    has_many :evidence_submissions, as: :supportable, dependent: :destroy
    has_many :status_updates, as: :statusable, dependent: :destroy

    def pdf_structure(version)
      Object.const_get(
        "AppealsApi::PdfConstruction::HigherLevelReview::#{version.upcase}::Structure"
      ).new(self)
    end

    # 1. VETERAN'S NAME
    def first_name
      auth_headers.dig('X-VA-First-Name')
    end

    def middle_initial
      auth_headers.dig('X-VA-Middle-Initial')
    end

    def last_name
      auth_headers.dig('X-VA-Last-Name')
    end

    def full_name
      "#{first_name} #{middle_initial} #{last_name}".squeeze(' ').strip
    end

    # 2. VETERAN'S SOCIAL SECURITY NUMBER
    def ssn
      auth_headers.dig('X-VA-SSN')
    end

    # 3. VA FILE NUMBER
    def file_number
      auth_headers.dig('X-VA-File-Number')
    end

    # 4. VETERAN'S DATE OF BIRTH
    def birth_mm
      birth_date.strftime '%m'
    end

    def birth_dd
      birth_date.strftime '%d'
    end

    def birth_yyyy
      birth_date.strftime '%Y'
    end

    # 5. VETERAN'S SERVICE NUMBER
    def service_number
      auth_headers.dig('X-VA-Service-Number')
    end

    # 6. INSURANCE POLICY NUMBER
    def insurance_policy_number
      auth_headers.dig('X-VA-Insurance-Policy-Number')
    end

    # 7. CLAIMANT'S NAME
    # 8. CLAIMANT TYPE

    # 9. CURRENT MAILING ADDRESS
    def number_and_street
      address_combined || 'USE ADDRESS ON FILE'
    end

    def city
      veteran.dig('address', 'city') || ''
    end

    def state_code
      veteran.dig('address', 'stateCode') || ''
    end

    def country_code
      return '' unless address_combined

      veteran.dig('address', 'countryCodeISO2') || 'US'
    end

    def zip_code_5
      veteran.dig('address', 'zipCode5') || '00000'
    end

    # 10. TELEPHONE NUMBER
    def veteran_phone_number
      veteran_phone.to_s
    end

    def veteran_phone_data
      veteran&.dig('phone')
    end

    def veteran_homeless?
      form_data&.dig('data', 'attributes', 'veteran', 'homeless')
    end

    # 11. E-MAIL ADDRESS
    def email
      veteran&.dig('emailAddressText').to_s.strip
    end

    def email_v2
      veteran&.dig('email').to_s.strip
    end

    # 12. BENEFIT TYPE
    def benefit_type
      data_attributes&.dig('benefitType').to_s.strip
    end

    # 13. IF YOU WOULD LIKE THE SAME OFFICE...
    def same_office
      data_attributes&.dig('sameOffice')
    end

    # 14. ...INFORMAL CONFERENCE...
    def informal_conference
      data_attributes&.dig('informalConference')
    end

    def informal_conference_times
      data_attributes&.dig('informalConferenceTimes') || []
    end

    def informal_conference_rep_name_and_phone_number
      "#{informal_conference_rep_name} #{informal_conference_rep_phone}"
    end

    def informal_conference_rep_phone_number
      informal_conference_rep_phone.to_s
    end

    def informal_conference_rep_ext
      informal_conference_rep&.dig('phone', 'phoneNumberExt')
    end

    def informal_conference_contact
      data_attributes&.dig('informalConferenceContact')
    end

    # V2 only allows one choice of conference time
    def informal_conference_time
      data_attributes&.dig('informalConferenceTime')
    end

    def rep_phone_data
      informal_conference_rep&.dig('phone')
    end

    def soc_opt_in
      data_attributes&.dig('socOptIn')
    end

    # 15. YOU MUST INDICATE BELOW EACH ISSUE...
    def contestable_issues
      form_data&.dig('included')
    end

    # 16B. DATE SIGNED
    def date_signed
      veterans_local_time.strftime('%m/%d/%Y')
    end

    def date_signed_mm
      veterans_local_time.strftime '%m'
    end

    def date_signed_dd
      veterans_local_time.strftime '%d'
    end

    def date_signed_yyyy
      veterans_local_time.strftime '%Y'
    end

    def consumer_name
      auth_headers&.dig('X-Consumer-Username')
    end

    def consumer_id
      auth_headers&.dig('X-Consumer-ID')
    end

    def update_status!(status:, code: nil, detail: nil)
      handler = Events::Handler.new(event_type: :hlr_status_updated, opts: {
                                      from: self.status,
                                      to: status,
                                      status_update_time: Time.zone.now,
                                      statusable_id: id
                                    })

      update!(status: status, code: code, detail: detail)

      handler.handle!
    end

    def informal_conference_rep
      data_attributes&.dig('informalConferenceRep')
    end

    private

    def data_attributes
      form_data&.dig('data', 'attributes')
    end

    def veteran
      data_attributes&.dig('veteran')
    end

    def birth_date_string
      auth_headers.dig('X-VA-Birth-Date')
    end

    def custom_validation
      HlrModelValidations.new(self).call
    end
  end
end
