# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  let(:assertion_xml) { build_signed_assertion(acme) }

  context 'when the signed Assertion is in a Response signed with an unregistered key' do
    let(:xml) { sign(Xml::Kit::KeyPair.generate(use: :signing), assertion_xml) }

    it 'is invalid' do
      expect(response.assertion).to be_trusted
      expect(response).to be_invalid
      expect(response.errors.full_messages).to contain_exactly('Fingerprint is not registered.')
    end
  end

  context 'when the signed Assertion is in a Response signed with another registered key' do
    let(:xml) { sign(acme.key_pairs(use: :signing).first, assertion_xml) }

    before do
      assertion_xml
      acme.generate_key_pair_for(use: :signing)
      registry.register(metadata_for(acme))
    end

    it 'is valid' do
      expect(response.signature.certificate).not_to eql(response.assertion.signature.certificate)
      expect(response).to be_valid
    end
  end
end
