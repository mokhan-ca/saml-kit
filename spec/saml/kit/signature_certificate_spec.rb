# frozen_string_literal: true

RSpec.describe Saml::Kit::Signature do
  include_context 'with identity providers'

  def with_certificate(xml, value)
    document = Nokogiri::XML(xml)
    document.xpath('//ds:X509Certificate', Saml::Kit::Document::NAMESPACES).each { |x| x.content = value }
    document.to_xml(save_with: as_xml)
  end

  def with_unreadable_dates(certificate)
    Base64.strict_encode64(certificate.x509.to_der.gsub(/\d{12}Z/n, "#{'9' * 12}Z"))
  end

  shared_examples 'an unreadable certificate' do
    it 'is missing from a signed Response' do
      expect(response.signature.certificate).to be_nil
      expect(response).to be_invalid
      expect(response.errors[:base]).to include('is missing.')
      expect(response).not_to be_trusted
    end

    it 'is missing from a signed Assertion' do
      response = Saml::Kit::Response.new(with_certificate(build_xml_with_signed_assertion(acme), value), configuration: configuration)
      expect(response).to be_invalid
      expect(response.errors[:assertion]).to include('is missing.')
      expect(response.assertion).not_to be_trusted
    end
  end

  let(:xml) { with_certificate(build_xml(acme), value) }

  ['', 'garbage', Base64.strict_encode64('garbage'), "-----BEGIN CERTIFICATE-----\nx\n-----END CERTIFICATE-----"].each do |certificate|
    context "with #{certificate.inspect}" do
      let(:value) { certificate }

      it_behaves_like 'an unreadable certificate'
    end
  end

  context 'with dates that are out of range' do
    let(:value) { with_unreadable_dates(acme.certificates.first) }

    it_behaves_like 'an unreadable certificate'
  end
end
