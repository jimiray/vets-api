# frozen_string_literal: true

module ClaimsApi
  module Headers
    class FirstNameSwagger
      include Swagger::Blocks

      swagger_component do
        parameter :first_name_header do
          key :name, 'X-VA-First-Name'
          key :in, :header
          key :description, 'First Name of Veteran being represented'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
