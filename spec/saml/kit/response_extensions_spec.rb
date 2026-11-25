# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  let(:namespaces) { described_class::NAMESPACES }
  let(:document) { Nokogiri::XML(encrypted_for(user)) }
  let(:other) { Nokogiri::XML(encrypted_for(UserWithoutAttributes.new)) }
  let(:xml) do
    extensions = document.create_element('Extensions')
    extensions << other.at_xpath('//xmlenc:EncryptedData', namespaces)
    document.at_xpath('/samlp:Response/samlp:Status', namespaces).add_previous_sibling(extensions)
    document.to_xml(save_with: as_xml)
  end

  def encrypted_for(user)
    described_class.build_xml(user, request, configuration: acme) do |x|
      x.embed_signature = false
      x.assertion.embed_signature = true
      x.encrypt_with(configuration.key_pairs(use: :encryption).last)
    end
  end

  it 'reads the Assertion and not other encrypted data' do
    expect(response.name_id).to eql(user.name_id)
    expect(response).to be_valid
  end
end
