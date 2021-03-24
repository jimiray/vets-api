module ClaimsApi
  module Headers
    class ApiKeySwagger
      include Swagger::Blocks

      swagger_component do
        parameter :api_key_header do
          key :name, 'apikey'
          key :in, :header
          key :description, 'API Key given to access data'
          key :required, true
          key :type, :string
        end
      end
    end
  end
end
