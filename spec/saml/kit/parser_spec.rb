# frozen_string_literal: true

RSpec.describe Saml::Kit::Parser do
  let(:xml) { without_declaration(Saml::Kit::AuthenticationRequest.build_xml) }
  let(:metadata) do
    without_declaration(
      Saml::Kit::IdentityProviderMetadata.build_xml { |x| x.add_single_sign_on_service('https://idp.example.com/login') }
    )
  end

  def without_declaration(xml)
    xml.sub(/\A<\?xml.*?\?>\s*/, '')
  end

  describe '.parse' do
    it 'parses well formed xml' do
      expect(described_class.parse(xml).root.name).to eql('AuthnRequest')
    end

    %w[UTF-16 UTF-16BE ISO-8859-1].each do |encoding|
      it "reads #{encoding} as utf-8" do
        document = described_class.parse(Nokogiri::XML('<a>é</a>').to_xml(encoding: encoding).b)
        expect(document.root.to_s).to eql('<a>é</a>')
      end
    end

    it 'keeps a document without an encoding' do
      expect(described_class.parse('<a/>').encoding).to be_nil
    end

    it 'reads a Response in UTF-16' do
      xml = Nokogiri::XML(Saml::Kit::Response.build_xml(UserWithoutAttributes.new)).to_xml(encoding: 'UTF-16')
      response = Saml::Kit::Document.to_saml_document(xml.b)
      expect(response).to be_invalid
      expect(response.name_id).to be_present
    end

    ['', nil, 'NOT XML', '<a>', '<a/><b/>', '<a/>b', '<!DOCTYPE a><a/>', '<!DOCTYPE a [<!ENTITY b "c">]><a>&b;</a>'].each do |refused|
      it "returns an empty document for #{refused.inspect}" do
        expect(described_class.parse(refused).root).to be_nil
      end
    end
  end

  shared_examples 'refused xml' do |change|
    let(:refused) { change.call(xml) }
    let(:refused_metadata) { change.call(metadata) }

    it 'is an invalid document' do
      expect(Saml::Kit::Document.to_saml_document(refused)).to be_instance_of(Saml::Kit::InvalidDocument)
    end

    it 'is an invalid document when posted' do
      params = { 'SAMLRequest' => Base64.strict_encode64(refused) }
      result = Saml::Kit::Bindings::HttpPost.new(location: '').deserialize(params)
      expect(result).to be_instance_of(Saml::Kit::InvalidDocument)
    end

    it 'has nothing to read' do
      document = Saml::Kit::AuthenticationRequest.new(refused)
      expect(document.id).to be_nil
      expect(document.issuer).to be_nil
      expect(document).to be_invalid
    end

    it 'is not an assertion' do
      assertion = Saml::Kit::Response.build(UserWithoutAttributes.new).assertion.to_xml
      expect(Saml::Kit::Assertion.new(assertion).id).to be_present
      expect(Saml::Kit::Assertion.new(change.call(assertion)).id).to be_nil
    end

    it 'is not metadata' do
      expect(Saml::Kit::Metadata.from(refused_metadata)).to be_nil
      expect(Saml::Kit::IdentityProviderMetadata.new(refused_metadata)).to be_invalid
    end

    it 'is not registered' do
      registry = Saml::Kit::DefaultRegistry.new
      expect { registry.register(Saml::Kit::Metadata.from(refused_metadata)) }.to raise_error(ArgumentError)
    end
  end

  describe 'content after the document' do
    it_behaves_like 'refused xml', ->(xml) { "#{xml}<junk/>" }
  end

  describe 'a document type declaration' do
    it_behaves_like 'refused xml', ->(xml) { "<!DOCTYPE saml>#{xml}" }
  end
end
