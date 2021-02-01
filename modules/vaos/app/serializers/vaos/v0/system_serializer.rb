# frozen_string_literal: true

require 'jsonapi/serializer'

module VAOS
  module V0
    class SystemSerializer
      include JSONAPI::Serializer

      set_id :unique_id
      attributes :unique_id,
                 :assigning_authority,
                 :assigning_code,
                 :id_status
    end
  end
end
