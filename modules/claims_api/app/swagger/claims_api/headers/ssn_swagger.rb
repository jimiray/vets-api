# frozen_string_literal: true

module ClaimsApi
  module Headers
    class SsnSwagger
      include Swagger::Blocks

      swagger_component do
        parameter :ssn_header do
          key :name, 'X-VA-SSN'
          key :in, :header
          key :description, 'SSN of Veteran being represented'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
