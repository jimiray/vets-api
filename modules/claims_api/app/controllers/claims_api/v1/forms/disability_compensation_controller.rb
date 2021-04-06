# frozen_string_literal: true

require 'evss/disability_compensation_form/service'
require 'evss/disability_compensation_form/service_exception'
require 'evss/error_middleware'
require 'common/exceptions'
require 'jsonapi/parser'

module ClaimsApi
  module V1
    module Forms
      class DisabilityCompensationController < ClaimsApi::V1::Forms::Base
        include ClaimsApi::PoaVerification
        include ClaimsApi::DocumentValidations

        FORM_NUMBER = '526'
        STATSD_VALIDATION_FAIL_KEY = 'api.claims_api.526.validation_fail'
        STATSD_VALIDATION_FAIL_TYPE_KEY = 'api.claims_api.526.validation_fail_type'

        before_action except: %i[schema] do
          permit_scopes %w[claim.write]
        end
        skip_before_action :validate_json_format, only: %i[upload_supporting_documents]
        before_action :verify_power_of_attorney_using_bgs_service, if: :header_request?

        # POST to submit disability claim.
        #
        # @return [JSON] Record in pending state
        def submit_form_526 # rubocop:disable Metrics/MethodLength
          validate_json_schema
          validate_initial_claim

          auto_claim = ClaimsApi::AutoEstablishedClaim.create(
            status: ClaimsApi::AutoEstablishedClaim::PENDING,
            auth_headers: auth_headers,
            form_data: form_attributes,
            flashes: flashes,
            special_issues: special_issues_per_disability,
            source: source_name
          )
          unless auto_claim.id
            existing_auto_claim = ClaimsApi::AutoEstablishedClaim.find_by(md5: auto_claim.md5, source: source_name)
            auto_claim = existing_auto_claim if existing_auto_claim.present?
          end

          if auto_claim.errors.present?
            raise ::Common::Exceptions::UnprocessableEntity.new(detail: auto_claim.errors.messages.to_s)
          end

          unless form_attributes['autoCestPDFGenerationDisabled'] == true
            ClaimsApi::ClaimEstablisher.perform_async(auto_claim.id)
          end

          render json: auto_claim, serializer: ClaimsApi::AutoEstablishedClaimSerializer
        end

        # PUT to upload a wet-signed 526 form.
        # Required if first ever claim for Veteran.
        #
        # @return [JSON] Claim record
        def upload_form_526
          validate_documents_content_type
          validate_documents_page_size

          pending_claim = ClaimsApi::AutoEstablishedClaim.pending?(params[:id])

          if pending_claim && (pending_claim.form_data['autoCestPDFGenerationDisabled'] == true)
            pending_claim.set_file_data!(documents.first, params[:doc_type])
            pending_claim.save!

            ClaimsApi::ClaimEstablisher.perform_async(pending_claim.id)
            ClaimsApi::ClaimUploader.perform_async(pending_claim.id)

            render json: pending_claim, serializer: ClaimsApi::AutoEstablishedClaimSerializer
          elsif pending_claim && (pending_claim.form_data['autoCestPDFGenerationDisabled'] == false)
            # rubocop:disable Layout/LineLength
            render json: { status: 422, message: 'Claim submission requires that the "autoCestPDFGenerationDisabled" field must be set to "true" in order to allow a 526 PDF to be uploaded' }.to_json, status: :unprocessable_entity
            # rubocop:enable Layout/LineLength
          else
            render json: { status: 404, message: 'Claim not found' }.to_json, status: :not_found
          end
        rescue => e
          render json: unprocessable_response(e), status: :unprocessable_entity
        end

        # POST to upload additional documents to support relevent disability compensation claim.
        #
        # @return [JSON] Claim record
        def upload_supporting_documents
          validate_documents_content_type
          validate_documents_page_size

          claim = ClaimsApi::AutoEstablishedClaim.get_by_id_or_evss_id(params[:id])
          raise ::Common::Exceptions::ResourceNotFound.new(detail: "Claim not found: #{params[:id]}") unless claim

          documents.each do |document|
            claim_document = claim.supporting_documents.build
            claim_document.set_file_data!(document, params[:doc_type], params[:description])
            claim_document.save!
            ClaimsApi::ClaimUploader.perform_async(claim_document.id)
          end

          render json: claim, serializer: ClaimsApi::ClaimDetailSerializer, uuid: claim.id
        end

        # POST to validate 526 submission payload.
        #
        # @return [JSON] Success if valid, error messages if invalid.
        # rubocop:disable Metrics/MethodLength
        def validate_form_526
          add_deprecation_headers_to_response(response: response, link: ClaimsApi::EndpointDeprecation::V1_DEV_DOCS)
          validate_json_schema
          validate_initial_claim

          service = EVSS::DisabilityCompensationForm::Service.new(auth_headers)
          auto_claim = ClaimsApi::AutoEstablishedClaim.new(
            status: ClaimsApi::AutoEstablishedClaim::PENDING,
            auth_headers: auth_headers,
            form_data: form_attributes
          )
          service.validate_form526(auto_claim.to_internal)
          render json: valid_526_response
        rescue ::EVSS::DisabilityCompensationForm::ServiceException, EVSS::ErrorMiddleware::EVSSError => e
          error_details = e.is_a?(EVSS::ErrorMiddleware::EVSSError) ? e.details : e.messages
          track_526_validation_errors(error_details)
          render json: { errors: format_526_errors(error_details) }, status: :unprocessable_entity
        rescue ::Common::Exceptions::GatewayTimeout,
               ::Timeout::Error,
               ::Faraday::TimeoutError,
               Breakers::OutageException => e
          req = { auth: auth_headers, form: form_attributes, source: source_name, auto_claim: auto_claim.as_json }
          PersonalInformationLog.create(
            error_class: "validate_form_526 #{e.class.name}", data: { request: req, error: e.try(:as_json) || e }
          )
          raise e
        end
        # rubocop:enable Metrics/MethodLength

        private

        def flashes
          initial_flashes = form_attributes.dig('veteran', 'flashes') || []
          homelessness = form_attributes.dig('veteran', 'homelessness')
          is_terminally_ill = form_attributes.dig('veteran', 'isTerminallyIll')

          initial_flashes.push('Homeless') if homelessness.present?
          initial_flashes.push('Terminally Ill') if is_terminally_ill.present? && is_terminally_ill

          initial_flashes.present? ? initial_flashes.uniq : []
        end

        def special_issues_per_disability
          (form_attributes['disabilities'] || []).map { |disability| special_issues_for_disability(disability) }
        end

        def special_issues_for_disability(disability)
          primary_special_issues = disability['specialIssues'] || []
          secondary_special_issues = []
          (disability['secondaryDisabilities'] || []).each do |secondary_disability|
            secondary_special_issues += (secondary_disability['specialIssues'] || [])
          end
          special_issues = primary_special_issues + secondary_special_issues

          mapper = ClaimsApi::SpecialIssueMappers::Bgs.new
          {
            code: disability['diagnosticCode'],
            name: disability['name'],
            special_issues: special_issues.map { |special_issue| mapper.code_from_name!(special_issue) }
          }
        end

        def validate_initial_claim
          if claims_service.claims_count.zero? && form_attributes['autoCestPDFGenerationDisabled'] == false
            error = {
              errors: [
                {
                  status: 422,
                  detail: 'Veteran has no claims, autoCestPDFGenerationDisabled requires true for Initial Claim'
                }
              ]
            }
            render json: error, status: :unprocessable_entity
          end
        end

        def valid_526_response
          {
            data: {
              type: 'claims_api_auto_established_claim_validation',
              attributes: {
                status: 'valid'
              }
            }
          }.to_json
        end

        def format_526_errors(errors)
          errors.map do |error|
            { status: 422, detail: "#{error['key']} #{error['detail']}", source: error['key'] }
          end
        end

        def track_526_validation_errors(errors)
          StatsD.increment STATSD_VALIDATION_FAIL_KEY

          errors.each do |error|
            key = error['key']&.gsub(/\[(.*?)\]/, '')
            StatsD.increment STATSD_VALIDATION_FAIL_TYPE_KEY, tags: ["key: #{key}"]
          end
        end

        def unprocessable_response(e)
          log_message_to_sentry('Upload error in 526', :error, body: e.message)

          {
            errors: [{ status: 422, detail: e&.message, source: e&.key }]
          }.to_json
        end
      end
    end
  end
end
