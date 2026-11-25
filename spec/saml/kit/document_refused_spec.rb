# frozen_string_literal: true

RSpec.describe Saml::Kit::Document do
  def empty_xml(name)
    "<samlp:#{name} xmlns:samlp=\"#{Saml::Kit::Namespaces::PROTOCOL}\"/>"
  end

  documents = {
    'AuthnRequest' => Saml::Kit::AuthenticationRequest,
    'InvalidDocument' => Saml::Kit::InvalidDocument,
    'LogoutRequest' => Saml::Kit::LogoutRequest,
    'LogoutResponse' => Saml::Kit::LogoutResponse,
    'Response' => Saml::Kit::Response,
  }

  documents.each do |name, type|
    it "translates each error of a refused #{name}" do
      [type.new('NOT XML'), type.new(empty_xml(name))].each do |document|
        expect(document).to be_invalid
        expect(document.errors.full_messages.grep(/translation missing/i)).to be_empty
      end
    end
  end

  it 'translates the request id of a refused LogoutResponse' do
    document = Saml::Kit::LogoutResponse.new(empty_xml('LogoutResponse'), request_id: SecureRandom.uuid)
    expect(document).to be_invalid
    expect(document.errors[:in_response_to]).to contain_exactly('must match request id.')
  end

  it 'translates each error of a refused Assertion' do
    document = Saml::Kit::Assertion.new("<Assertion xmlns=\"#{Saml::Kit::Namespaces::ASSERTION}\"/>")
    expect(document).to be_invalid
    expect(document.errors.full_messages.grep(/translation missing/i)).to be_empty
  end
end
