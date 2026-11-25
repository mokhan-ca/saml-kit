# frozen_string_literal: true

RSpec.shared_context 'with identity providers' do
  subject(:response) { Saml::Kit::Response.new(xml, configuration: configuration) }

  let(:as_xml) { Nokogiri::XML::Node::SaveOptions::AS_XML }
  let(:user) { UserWithoutAttributes.new }
  let(:request) { Saml::Kit::AuthenticationRequest.build(configuration: configuration) }
  let(:acme) { identity_provider('https://acme.example.com/metadata') }
  let(:initech) { identity_provider('https://initech.example.com/metadata') }
  let(:registry) { Saml::Kit::DefaultRegistry.new }
  let(:configuration) do
    Saml::Kit::Configuration.new do |x|
      x.entity_id = 'https://www.example.com/metadata'
      x.registry = registry
      x.generate_key_pair_for(use: :encryption)
    end
  end

  before { [acme, initech].each { |x| registry.register(metadata_for(x)) } }

  def identity_provider(entity_id)
    Saml::Kit::Configuration.new do |x|
      x.entity_id = entity_id
      x.generate_key_pair_for(use: :signing)
    end
  end

  def metadata_for(configuration)
    Saml::Kit::IdentityProviderMetadata.build(configuration: configuration) do |x|
      x.add_single_sign_on_service("#{configuration.entity_id}/login")
    end
  end

  def build_xml(provider, issuer: provider.entity_id)
    Saml::Kit::Response.build_xml(user, request, configuration: provider) do |x|
      x.issuer = issuer
      x.embed_signature = true
      x.assertion.embed_signature = false
      yield x if block_given?
    end
  end

  def build_xml_with_signed_assertion(provider)
    build_xml(provider) do |x|
      x.embed_signature = false
      x.assertion.embed_signature = true
    end
  end

  def build_signed_assertion(provider)
    xml = build_xml_with_signed_assertion(provider)
    Saml::Kit::Response.new(xml).assertion.to_nokogiri.to_xml(save_with: as_xml)
  end

  def sign(key_pair, content)
    id = Xml::Kit::Id.generate
    Xml::Kit::Signatures.sign(key_pair: key_pair) do |xml, signature|
      xml.Response ID: id, Version: '2.0', IssueInstant: Time.now.utc.iso8601, xmlns: Saml::Kit::Namespaces::PROTOCOL do
        xml.Issuer acme.entity_id, xmlns: Saml::Kit::Namespaces::ASSERTION
        signature.template(id)
        xml.Status { xml.StatusCode Value: Saml::Kit::Namespaces::SUCCESS }
        xml << content
      end
    end
  end
end
