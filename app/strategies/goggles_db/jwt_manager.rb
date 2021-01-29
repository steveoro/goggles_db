# frozen_string_literal: true

require 'jwt'

module GogglesDb
  #
  # = Jwt Manager strategy object
  #
  #   - file vers.: 1.03
  #   - author....: Steve A.
  #   - build.....: 20210128
  #
  #   Wraps encoding & decoding helper methods for JSON Web Token usage.
  #
  class JwtManager
    # Default token duration for the encoded JWT, after which it will expire
    TOKEN_LIFE = 2.hours

    # Constructor
    #
    # === Params
    # - base_key: the secret key used for the encode/decode.
    # - default_expiry_in: default JWT life length; specify N.minutes, N.hours or whatsoever; defaults to TOKEN_LIFE.
    #
    def initialize(base_key, jwt_expires_in)
      @base_key = base_key
      @jwt_expires_in = jwt_expires_in
    end

    # Encodes a payload into an expirable JWT given the construction parameters.
    #
    # === Params
    # - payload_hash: an Hash to be used as payload.
    #
    # === Returns
    # A JWT encoded string.
    #
    def encode(payload_hash)
      JwtManager.encode(payload_hash, @base_key, @jwt_expires_in)
    end

    # Encodes a payload into an expirable JWT.
    #
    # === Params
    # - payload_hash: an Hash to be used as payload.
    # - base_key: the secret key used for the encoding algorithm.
    # - override_life: JWT length, specify N.minutes, N.hours or whatsoever; defaults to TOKEN_LIFE.
    #
    # === Returns
    # A JWT encoded string.
    #
    def self.encode(payload_hash, base_key, override_life = TOKEN_LIFE)
      # Create the JWT token and store the Hash payload as the data member:
      expirable_payload = {
        data: payload_hash,
        exp: (Time.current + override_life).to_i
      }
      JWT.encode(expirable_payload, base_key, 'HS512')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Decodes and returns a payload hash from a given JWT.
    #
    # === Params
    # - jwt_token: the JWT string that has to be decoded.
    #
    # === Returns
    # An HashWithIndifferentAccess for the decoded payload or nil in case of errors.
    #
    # Typical format:
    # [
    #   { 'data' => { ...actual payload...}, 'exp' => expiry_time,
    #    ' alg' => 'HS512' }
    # ]
    #
    def decode(jwt_token)
      JwtManager.decode(jwt_token, @base_key)
    end

    # Decodes and returns a payload hash from a given JWT.
    #
    # === Params
    # - jwt_token: the JWT string that has to be decoded.
    # - base_key: the secret key used for the decoding algorithm.
    #
    # === Returns
    # An HashWithIndifferentAccess for the decoded payload or nil in case of errors.
    # See #decode(jwt_token) for format info.
    #
    def self.decode(jwt_token, base_key)
      HashWithIndifferentAccess.new(
        JWT.decode(jwt_token, base_key, true, algorithm: 'HS512').first
      )['data']
    rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
      # Verbose output for debugging purposes:
      # puts $!
      nil
    end
  end
end
