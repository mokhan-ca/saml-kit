# frozen_string_literal: true

module Saml
  module Kit
    module Assertable
      def provider
        metadata = super
        metadata.respond_to?(:identity_provider) ? metadata.identity_provider : metadata
      end
    end
  end
end
