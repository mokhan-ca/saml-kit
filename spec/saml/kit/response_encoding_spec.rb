# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  let(:xml) { sign(acme.key_pairs(use: :signing).last, encrypt(plaintext)) }
  let(:plaintext) { build_signed_assertion(acme).sub('<Assertion', "<\xC1ssertion") }

  def encrypt(content)
    cipher = Xml::Kit::Crypto.cipher_for(
      "#{Xml::Kit::Namespaces::XMLENC}rsa-oaep-mgf1p",
      configuration.certificates(use: :encryption).last.public_key
    )
    data = Xml::Kit::EncryptedData.new(content, asymmetric_cipher: cipher).to_xml
    "<EncryptedAssertion xmlns=\"#{Saml::Kit::Namespaces::ASSERTION}\">#{data}</EncryptedAssertion>"
  end

  it 'is invalid when the plaintext is not valid UTF-8' do
    expect(response).to be_invalid
    expect(response.errors[:assertion]).to include('cannot be decrypted.')
  end
end
