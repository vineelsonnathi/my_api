require 'google/api_client'

module API
  class GoogleApi < Base
    class << self

      def pre_load_files
        @config = YAML.load(open("#{Rails.root}/config/initializers/google_api_secrets.yml"))
        file_path = File.join(Rails.root, 'config', 'initializers', 'Chideo_Admin_305a867cdd4b.p12')
        @key = Google::APIClient::KeyUtils.load_from_pkcs12(file_path, @config['service_account']['password'])
      end

      def initialize_google_client_instance
        @client = Google::APIClient.new(  
          application_name:     @config['google']['application_name'], 
          application_version:  @config['google']['application_version']
        )
      end

      def request_oauth_authorization
        @client.authorization = Signet::OAuth2::Client.new(
          token_credential_uri: @config['authorization']['token_credential_uri'],
          audience:             @config['authorization']['audience_uri'],
          scope:                @config['discover_api']['analytics'],
          issuer:               @config['authorization']['service_email'] ,
          signing_key:          @key
         ).tap { |auth| auth.fetch_access_token! }
      end

      def call_google_analytics_api
        @api_method = @client.discovered_api('analytics','v3').data.ga.get
      end

      def execute_query(params)
        authorize
        @result = @client.execute(:api_method => @api_method, :parameters => {
          'ids'        => @config['google']['ids'],
          'dimensions' => params[:dimensions].join(","),
          'metrics'    => params[:metrics].join(","),
          'start-date' => params[:start_date].to_date.to_s,
          'end-date'   => params[:end_date].to_date.to_s,
          'max-results'=> params[:max_records],
          'sort'       => "-#{params[:metrics].first}"
        })
      end

      def authorize
        pre_load_files
        initialize_google_client_instance
        request_oauth_authorization
        call_google_analytics_api
      end

    end
  end
end