module ClaimsApi
  module Entities
    module V2
      class ClaimEntity < Grape::Entity
        expose :id, documentation: { type: 'String' } do |instance, _options|
          valid_identifier(instance)
        end
        expose :self do |instance, _options|
          "http://localhost:3000/services/claims/v2/claims/#{valid_identifier(instance)}"
        end
        expose :attributes, documentation: { type: Hash, desc: 'Additional attributes' } do
          expose :evss_id, as: :vbms_claim_id, documentation: { type: Integer }
          expose :status, documentation: { type: 'String' } do |instance, _options|
            if instance.respond_to?(:status)
              instance.status
            elsif instance.respond_to?(:list_data)
              instance.list_data['status'].downcase
            end
          end
        end

        private

        def valid_identifier(instance)
          return instance.id if instance.respond_to?(:id)
          return nil unless instance.respond_to?(:evss_id)

          claim = ClaimsApi::AutoEstablishedClaim.find_by(evss_id: instance.evss_id)
          return claim.id if claim.present?

          instance.respond_to?(:evss_id) ? instance.evss_id : nil
        end
      end
    end
  end
end
