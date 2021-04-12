require 'doorkeeper/request/strategy'

module Doorkeeper
  module Request
    class AuthorizationCode < Strategy
      delegate :grant, :client, :parameters, to: :server
      delegate :client_via_uid, :parameters, to: :server

      def request
        @request ||= OAuth::AuthorizationCodeRequest.new(
          Doorkeeper.configuration,
          grant,
          client_for_request,
          parameters
        )
      end

      def client_for_request
        if parameters.include?(:code_verifier) && parameters[:code_verifier].present?
          client_via_uid
        else
          client
        end
      end
    end
  end
end
