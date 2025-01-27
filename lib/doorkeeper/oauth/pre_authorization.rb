module Doorkeeper
  module OAuth
    class PreAuthorization
      include Validations

      validate :response_type, error: :unsupported_response_type
      validate :client, error: :invalid_client
      validate :scopes, error: :invalid_scope
      validate :redirect_uri, error: :invalid_redirect_uri
      validate :code_challenge_method, error: :invalid_code_challenge_method

      attr_accessor :server, :client, :response_type, :redirect_uri, :state,
                    :code_challenge, :code_challenge_method
      attr_writer   :scope

      def initialize(server, client, attrs = {})
        @server        = server
        @client        = client
        @response_type = attrs[:response_type]
        @redirect_uri  = attrs[:redirect_uri]
        @scope         = attrs[:scope]
        @state         = attrs[:state]
        @code_challenge = attrs[:code_challenge]
        @code_challenge_method = attrs[:code_challenge_method]
      end

      def authorizable?
        valid?
      end

      def scopes
        Scopes.from_string scope
      end

      def scope
        @scope.presence || server.default_scopes.to_s
      end

      def error_response
        OAuth::ErrorResponse.from_request(self)
      end

      private

      def validate_response_type
        server.authorization_response_types.include? response_type
      end

      def validate_client
        client.present?
      end

      def validate_scopes
        return true unless scope.present?

        Helpers::ScopeChecker.valid?(
          scope,
          server.scopes,
          client.application.scopes
        )
      end

      # TODO: test uri should be matched against the client's one
      def validate_redirect_uri
        return false unless redirect_uri.present?

        Helpers::URIChecker.native_uri?(redirect_uri) ||
          Helpers::URIChecker.valid_for_authorization?(redirect_uri, client.redirect_uri)
      end

      def validate_code_challenge_method
        !code_challenge.present? || (code_challenge_method.present? && code_challenge_method =~ /^plain$|^S256$/)
      end
    end
  end
end
