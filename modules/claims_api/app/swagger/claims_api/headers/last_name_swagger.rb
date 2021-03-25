module ClaimsApi
  module Headers
    class LastNameSwagger
      include Swagger::Blocks

      swagger_component do
        parameter :last_name_header do
          key :name, 'X-VA-Last-Name'
          key :in, :header
          key :description, 'Last Name of Veteran being represented'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
