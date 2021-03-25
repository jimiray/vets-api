# frozen_string_literal: true

module ClaimsApi
  module Headers
    class LoaSwagger
      include Swagger::Blocks

      swagger_component do
        parameter :loa_header do
          key :name, 'X-VA-LOA'
          key :in, :header
          key :description, 'The level of assurance of the user making the request'
          key :example, '3'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
