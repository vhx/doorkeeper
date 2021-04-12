module UrlHelper
  def token_endpoint_url(options = {})
    parameters = {
      code: options[:code],
      client_id: options[:client_id]     || (options[:client] ? options[:client].uid : nil),
      client_secret: options[:client_secret] || (options[:client] ? options[:client].secret : nil),
      redirect_uri: options[:redirect_uri]  || (options[:client] ? options[:client].redirect_uri : nil),
      grant_type: options[:grant_type]    || 'authorization_code',
      code_verifier: options[:code_verifier],
      code_challenge_method: options[:code_challenge_method]
    }
    "/oauth/token?#{build_query(parameters)}"
  end

  def password_token_endpoint_url(options = {})
    parameters = {
      code: options[:code],
      client_id: options[:client_id]     || (options[:client] ? options[:client].uid : nil),
      client_secret: options[:client_secret] || (options[:client] ? options[:client].secret : nil),
      username: options[:resource_owner_username] || (options[:resource_owner] ? options[:resource_owner].name : nil),
      password: options[:resource_owner_password] || (options[:resource_owner] ? options[:resource_owner].password : nil),
      grant_type: 'password'
    }
    "/oauth/token?#{build_query(parameters)}"
  end

  def authorization_endpoint_url(options = {})
    parameters = {
      client_id: options[:client_id]     || options[:client].uid,
      redirect_uri: options[:redirect_uri]  || options[:client].redirect_uri,
      response_type: options[:response_type] || 'code',
      scope: options[:scope],
      state: options[:state],
      code_challenge: options[:code_challenge],
      code_challenge_method: options[:code_challenge_method]
    }.reject { |k, v| v.blank? }
    "/oauth/authorize?#{build_query(parameters)}"
  end

  def refresh_token_endpoint_url(options = {})
    parameters = {
      refresh_token: options[:refresh_token],
      client_id: options[:client_id]     || options[:client].uid,
      client_secret: options[:client_secret] || options[:client].secret,
      grant_type: options[:grant_type]    || 'refresh_token'
    }
    "/oauth/token?#{build_query(parameters)}"
  end

  def revocation_token_endpoint_url
    '/oauth/revoke'
  end

  def build_query(hash)
    Rack::Utils.build_query(hash)
  end
end

RSpec.configuration.send :include, UrlHelper
