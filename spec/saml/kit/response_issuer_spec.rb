# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  def without_issuer(xml)
    document = Nokogiri::XML(xml)
    document.at_xpath('/samlp:Response/saml:Issuer', described_class::NAMESPACES).remove
    document.to_xml(save_with: as_xml)
  end

  context 'when the Response and the Assertion have the same issuer' do
    let(:xml) { build_xml(acme) }

    specify { expect(response).to be_valid }
  end

  context 'when the Response and the Assertion have the same issuer and the Assertion is encrypted' do
    let(:xml) { build_xml(acme) { |x| x.encrypt_with(configuration.key_pairs(use: :encryption).last) } }

    specify { expect(response).to be_valid }
  end

  context 'when the Response and the Assertion have different issuers' do
    let(:xml) { build_xml(acme) { |x| x.assertion.issuer = initech.entity_id } }

    it 'is invalid' do
      expect(response).to be_invalid
      expect(response.errors.full_messages).to contain_exactly('Issuer must match the Assertion issuer.')
    end
  end

  context 'when the Response and the encrypted Assertion have different issuers' do
    let(:xml) do
      build_xml(acme) do |x|
        x.assertion.issuer = initech.entity_id
        x.encrypt_with(configuration.key_pairs(use: :encryption).last)
      end
    end

    it 'is invalid' do
      expect(response).to be_invalid
      expect(response.errors[:issuer]).to contain_exactly('must match the Assertion issuer.')
    end
  end

  context 'when an unsigned Response has a different issuer than the signed Assertion' do
    let(:xml) do
      build_xml_with_signed_assertion(acme).sub(acme.entity_id, initech.entity_id)
    end

    it 'is invalid' do
      expect(response.issuer).to eql(initech.entity_id)
      expect(response.assertion.issuer).to eql(acme.entity_id)
      expect(response).to be_invalid
      expect(response.errors.full_messages).to contain_exactly('Issuer must match the Assertion issuer.')
    end
  end

  context 'when the registry provides metadata without an issuer' do
    let(:registry) do
      Class.new(Saml::Kit::DefaultRegistry) do
        def metadata_for(issuer)
          issuer.nil? ? first : super
        end
      end.new
    end

    it 'accepts an unsigned Response around a signed Assertion' do
      xml = without_issuer(build_xml_with_signed_assertion(acme))
      expect(described_class.new(xml, configuration: configuration)).to be_valid
    end

    it 'requires an issuer on a Response delivered with a signature' do
      response = described_class.new(without_issuer(build_xml_with_signed_assertion(acme)), configuration: configuration)
      response.signature_verified!
      expect(response).to be_invalid
      expect(response.errors[:issuer]).to contain_exactly('must match the Assertion issuer.')
    end

    it 'requires an issuer on a Response around an encrypted Assertion' do
      xml = without_issuer(build_xml(acme) do |x|
        x.embed_signature = false
        x.assertion.embed_signature = true
        x.encrypt_with(configuration.key_pairs(use: :encryption).last)
      end)
      response = described_class.new(xml, configuration: configuration)
      expect(response).to be_invalid
      expect(response.errors[:issuer]).to contain_exactly('must match the Assertion issuer.')
    end
  end

  context 'when the Assertion cannot be decrypted' do
    let(:xml) { build_xml(acme) { |x| x.encrypt_with(Xml::Kit::KeyPair.generate(use: :encryption)) } }

    it 'does not report the issuer' do
      expect(response).to be_invalid
      expect(response.errors[:assertion]).to include('cannot be decrypted.')
      expect(response.errors[:issuer]).to be_empty
    end
  end
end
