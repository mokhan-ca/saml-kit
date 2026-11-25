# frozen_string_literal: true

module Saml
  module Kit
    # This class validates the Assertion
    # element nested in a Response element
    # of a SAML document.
    class Assertion < Document
      include Assertable
      extend Forwardable
      XPATH = [
        '/samlp:Response/saml:Assertion',
        '/samlp:Response/saml:EncryptedAssertion'
      ].join('|')
      def_delegators :conditions, :started_at, :expired_at, :audiences
      def_delegators :attribute_statement, :attributes

      validate :must_be_decryptable
      validate :must_match_issuer, if: :decryptable?
      validate :must_be_active_session, if: :decryptable?
      validate :must_have_valid_signature, if: :decryptable?
      attr_reader :name, :configuration
      attr_accessor :occurred_at

      def initialize(
        node, configuration: Saml::Kit.configuration, private_keys: []
      )
        @name = 'Assertion'
        @to_nokogiri = node.is_a?(String) ? Parser.parse(node).root : node
        @configuration = configuration
        @occurred_at = Time.current
        @encrypted = false
        keys = configuration.private_keys(use: :encryption) + private_keys
        decrypt(::Xml::Kit::Decryption.new(private_keys: keys.uniq))
        super(to_s, name: 'Assertion', configuration: configuration)
      end

      def id
        at_xpath('./@ID').try(:value)
      end

      def issuer
        at_xpath('./saml:Issuer').try(:text)
      end

      def version
        at_xpath('./@Version').try(:value)
      end

      def name_id
        at_xpath('./saml:Subject/saml:NameID').try(:text)
      end

      def name_id_format
        at_xpath('./saml:Subject/saml:NameID').attribute('Format').try(:value)
      end

      def signed?
        signature.present?
      end

      def signature
        @signature ||= Signature.new(at_xpath('./ds:Signature'))
      end

      def expired?(now = occurred_at)
        now > expired_at
      end

      def active?(now = occurred_at)
        drifted_started_at = started_at - configuration.clock_drift.to_i.seconds
        now > drifted_started_at && !expired?(now)
      end

      def expected_type?
        at_xpath('../saml:Assertion|../saml:EncryptedAssertion').present?
      end

      def attribute_statement(xpath = './saml:AttributeStatement')
        @attribute_statement ||= AttributeStatement.new(search(xpath))
      end

      def conditions
        @conditions ||= Conditions.new(search('./saml:Conditions'))
      end

      def encrypted?
        @encrypted
      end

      def decryptable?
        !encrypted? || !@cannot_decrypt
      end

      def to_s
        @to_nokogiri.to_s
      end

      private

      # A nested Assertion is covered by the enclosing Response's policy; a
      # bare one is the whole document and has nothing else vouching for it.
      def signature_required_by_type?
        to_nokogiri == to_nokogiri.document.root
      end

      def decrypt(decryptor)
        encrypted_data = at_xpath('./xmlenc:EncryptedData')
        @encrypted = encrypted_data.present?
        @to_nokogiri = decryptor.decrypt_node(copy(encrypted_data)) if encrypted?
      rescue StandardError => error
        @cannot_decrypt = true
        Saml::Kit.logger.error(error)
      end

      def copy(node)
        position = node.document.xpath('//*').index(node)
        node.document.dup.xpath('//*')[position]
      end

      def must_match_issuer
        return if audiences.empty? || audiences.include?(configuration.entity_id)

        errors.add(:audience, error_message(:must_match_issuer))
      end

      def must_be_active_session
        return if active?

        errors.add(:base, error_message(:expired))
      end

      def must_have_valid_signature
        return if !signed? || signature.valid?

        signature.each_error do |attribute, message|
          errors.add(attribute, message)
        end
      end

      def must_be_decryptable
        errors.add(:base, error_message(:cannot_decrypt)) unless decryptable?
      end
    end
  end
end
