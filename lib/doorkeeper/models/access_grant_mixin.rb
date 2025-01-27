module Doorkeeper
  module AccessGrantMixin
    extend ActiveSupport::Concern

    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Scopes
    include ActiveModel::MassAssignmentSecurity if defined?(::ProtectedAttributes)

    included do
      belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :access_grants

      if respond_to?(:attr_accessible)
        attr_accessible :resource_owner_id, :application_id, :expires_in, :redirect_uri, :scopes,
                        :code_challenge, :code_challenge_method
      end

      validates :resource_owner_id, :application_id, :token, :expires_in, :redirect_uri, presence: true
      validates :token, uniqueness: true

      before_validation :generate_token, on: :create
    end

    # never uses pkce, if pkce migrations were not generated
    def uses_pkce?
      pkce_supported? && code_challenge.present?
    end

    def pkce_supported?
      respond_to? :code_challenge
    end

    module ClassMethods
      def by_token(token)
        where(token: token.to_s).limit(1).to_a.first
      end

      # Implements PKCE code_challenge encoding without base64 padding as described in the spec.
      # https://tools.ietf.org/html/rfc7636#appendix-A
      #   Appendix A.  Notes on Implementing Base64url Encoding without Padding
      #
      #   This appendix describes how to implement a base64url-encoding
      #   function without padding, based upon the standard base64-encoding
      #   function that uses padding.
      #
      #       To be concrete, example C# code implementing these functions is shown
      #   below.  Similar code could be used in other languages.
      #
      #   static string base64urlencode(byte [] arg)
      #   {
      #       string s = Convert.ToBase64String(arg); // Regular base64 encoder
      #       s = s.Split('=')[0]; // Remove any trailing '='s
      #       s = s.Replace('+', '-'); // 62nd char of encoding
      #       s = s.Replace('/', '_'); // 63rd char of encoding
      #       return s;
      #   }
      #
      #   An example correspondence between unencoded and encoded values
      #   follows.  The octet sequence below encodes into the string below,
      #   which when decoded, reproduces the octet sequence.
      #
      #   3 236 255 224 193
      #
      #   A-z_4ME
      #
      # https://ruby-doc.org/stdlib-2.1.3/libdoc/base64/rdoc/Base64.html#method-i-urlsafe_encode64
      #
      # urlsafe_encode64(bin)
      # Returns the Base64-encoded version of bin. This method complies with
      # “Base 64 Encoding with URL and Filename Safe Alphabet” in RFC 4648.
      # The alphabet uses ‘-’ instead of ‘+’ and ‘_’ instead of ‘/’.

      # @param code_verifier [#to_s] a one time use value (any object that responds to `#to_s`)
      #
      # @return [#to_s] An encoded code challenge based on the provided verifier suitable for PKCE validation
      def generate_code_challenge(code_verifier)
        padded_result = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier))
        padded_result.split('=')[0] # Remove any trailing '='
      end

      def pkce_supported?
        new.pkce_supported?
      end
    end

    private

    def generate_token
      self.token = UniqueToken.generate
    end
  end
end
