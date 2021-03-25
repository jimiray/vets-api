# frozen_string_literal: true

module ClaimsApi
  module Headers
    class BirthDateSwagger
      include Swagger::Blocks

      swagger_component do
        parameter :birth_date_header do
          key :name, 'X-VA-Birth-Date'
          key :in, :header
          key :description, 'Date of Birth of Veteran being represented, in iso8601 format'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
