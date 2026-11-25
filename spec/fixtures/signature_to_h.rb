# frozen_string_literal: true

require 'bundler'
Bundler.setup(:default)
require 'saml/kit'

Saml::Kit.configuration.generate_key_pair_for(use: :signing)
request = Saml::Kit::AuthenticationRequest.build

print [request.to_h.keys, request.signature.to_h.keys, defined?(REXML)].inspect
