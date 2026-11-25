# frozen_string_literal: true

module Saml
  module Kit
    # This class is responsible for validating and
    # parsing a SAML Response document.
    # {include:file:spec/examples/response_spec.rb}
    class Response < Document
      include Assertable
      include Respondable
      extend Forwardable

      def_delegators :assertion, :name_id, :[], :attributes

      validate :must_be_valid_assertion
      validate :must_contain_single_assertion
      validate :must_match_assertion_issuer

      def initialize(
        xml,
        request_id: nil,
        configuration: Saml::Kit.configuration
      )
        @request_id = request_id
        super(xml, name: 'Response', configuration: configuration)
      end

      def assertion(private_keys = configuration.private_keys(use: :encryption))
        @assertion ||=
          begin
            node = assertion_nodes.last
            if node.nil?
              Saml::Kit::NullAssertion.new
            else
              Saml::Kit::Assertion.new(
                node,
                configuration: @configuration,
                private_keys: private_keys
              )
            end
          end
      end

      private

      def signature_required_by_type?
        true
      end

      # `signed?` and `trusted?` deliberately report only this element's own
      # signature, but signing only the Assertion is a common identity provider
      # configuration, and that signature covers the identity being asserted.
      def signature_covers_document?
        signed? || assertion.signed?
      end

      def signature_trusted?
        return super if signed?

        assertion.signed? && assertion.trusted?
      end

      def must_be_valid_assertion
        assertion.valid?
        assertion.each_error do |attribute, error|
          attribute = :assertion if attribute == :base
          errors.add(attribute, error) unless errors.added?(attribute, error)
        end
      end

      def must_contain_single_assertion
        return if assertion_nodes.empty? || assertion.search(Assertion::XPATH).one?

        errors.add(:base, error_message(:must_contain_single_assertion))
      end

      # SAML 2.0 Profiles 4.1.4.2, Errata E17 and E26
      def must_match_assertion_issuer
        return unless assertion.decryptable?
        return if issuer == assertion.issuer || issuer_omitted?

        errors.add(:issuer, error_message(:must_match_assertion_issuer))
      end

      def issuer_omitted?
        issuer.nil? && !signed? && !assertion.encrypted?
      end

      def assertion_nodes
        search(Saml::Kit::Assertion::XPATH)
      end
    end
  end
end
