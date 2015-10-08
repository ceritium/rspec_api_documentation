require 'rails_helper'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.format = [:swagger]
  config.curl_host = 'http://localhost:3000'
  config.api_name = "Example App API"
end
