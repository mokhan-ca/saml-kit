# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  context 'when the Response is signed and the Assertion is encrypted' do
    let(:xml) { build_xml(acme) { |x| x.encrypt_with(configuration.key_pairs(use: :encryption).last) } }

    it 'is valid more than once' do
      expect(response).to be_valid
      expect(response).to be_valid
    end

    it 'is valid after the Assertion is read' do
      expect(response.name_id).to eql(user.name_id)
      expect(response).to be_valid
    end

    it 'does not change the signed document' do
      original = response.to_nokogiri.canonicalize
      expect(response.assertion).to be_encrypted
      expect(response.to_nokogiri.canonicalize).to eql(original)
    end
  end

  context 'when more than one Assertion is encrypted together' do
    let(:xml) { sign(acme.key_pairs(use: :signing).last, encrypt(build_signed_assertion(acme) + build_signed_assertion(acme))) }

    def encrypt(content)
      cipher = Xml::Kit::Crypto.cipher_for(
        "#{Xml::Kit::Namespaces::XMLENC}rsa-oaep-mgf1p",
        configuration.certificates(use: :encryption).last.public_key
      )
      data = Xml::Kit::EncryptedData.new(content, asymmetric_cipher: cipher).to_xml
      "<EncryptedAssertion xmlns=\"#{Saml::Kit::Namespaces::ASSERTION}\">#{data}</EncryptedAssertion>"
    end

    it 'is invalid' do
      expect(response).to be_invalid
      expect(response.errors.full_messages).to contain_exactly('must contain a single Assertion.')
    end

    it 'is valid when the Assertion is alone' do
      expect(described_class.new(sign(acme.key_pairs(use: :signing).last, encrypt(build_signed_assertion(acme))), configuration: configuration)).to be_valid
    end
  end
end
