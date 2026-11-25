# frozen_string_literal: true

RSpec.describe Saml::Kit::XmlHash do
  def hash_from(xml)
    described_class.from(Nokogiri::XML(xml).root)
  end

  [
    '<a/>',
    '<a> </a>',
    '<a>b</a>',
    '<a b="1"/>',
    '<a b="1">c</a>',
    '<a><b/><b>c</b></a>',
    '<a b="1"><b>c</b></a>',
    '<a>b<c/>d</a>',
    '<a> <b/> </a>',
    '<a>b<!-- c -->d</a>',
    '<a>b<![CDATA[<c>]]>d</a>',
    '<a>b<?c d?>e</a>',
    '<a>&lt;&#233;</a>',
    '<a-b c-d="1"/>',
    '<a type="integer">1</a>',
    '<a type="array"><b>1</b></a>',
    '<a nil="true"/>',
    '<a xmlns="urn:a" xmlns:b="urn:b" b:c="1" xml:lang="en"><b:d xmlns=""/></a>',
  ].each do |xml|
    it "converts #{xml} like Hash.from_xml" do
      expect(hash_from(xml)).to eql(Hash.from_xml(xml) || {})
    end
  end

  it 'is empty without an element' do
    expect(described_class.from(nil)).to eql({})
  end

  describe '#to_h' do
    let(:configuration) { Saml::Kit::Configuration.new { |x| x.generate_key_pair_for(use: :signing) } }
    let(:response) { Saml::Kit::Response.build(UserWithoutAttributes.new, configuration: configuration) }

    it 'converts a document' do
      expect(response.to_h).to eql(Hash.from_xml(response.to_xml))
    end

    it 'converts the assertion and its parts' do
      [response.assertion, response.assertion.conditions].each do |part|
        expect(part.to_h).to eql(Hash.from_xml(part.to_xml))
      end
    end

    it 'converts the signature' do
      expect(response.signature.to_h).to eql(Hash.from_xml(response.signature.to_xml)['Signature'])
    end

    it 'converts an element that uses a prefix from its parent' do
      xml = <<~XML
        <samlp:Response xmlns:samlp="#{Saml::Kit::Namespaces::PROTOCOL}" xmlns:saml="#{Saml::Kit::Namespaces::ASSERTION}">
          <saml:Assertion ID="_1"><saml:Issuer>acme</saml:Issuer></saml:Assertion>
        </samlp:Response>
      XML
      expect(Saml::Kit::Response.new(xml).assertion.to_h).to eql('Assertion' => { 'ID' => '_1', 'Issuer' => 'acme' })
    end

    it 'is empty when the document is refused' do
      expect(Saml::Kit::Response.new('NOT XML').to_h).to eql({})
    end
  end
end
