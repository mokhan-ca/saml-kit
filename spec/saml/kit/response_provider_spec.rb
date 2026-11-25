# frozen_string_literal: true

RSpec.describe Saml::Kit::Response do
  include_context 'with identity providers'

  let(:xml) { build_xml(acme) }
  let(:service_provider) do
    Saml::Kit::ServiceProviderMetadata.build(configuration: acme) do |x|
      x.add_assertion_consumer_service("#{acme.entity_id}/acs")
    end
  end

  def composite_of(identity_provider:, service_provider:)
    Saml::Kit::Metadata.build(configuration: acme) do |x|
      x.identity_provider = Saml::Kit::IdentityProviderMetadata.builder(configuration: identity_provider) do |y|
        y.add_single_sign_on_service("#{acme.entity_id}/login")
      end
      x.service_provider = Saml::Kit::ServiceProviderMetadata.builder(configuration: service_provider) do |y|
        y.add_assertion_consumer_service("#{acme.entity_id}/acs")
      end
    end
  end

  shared_examples 'a Response that is not from an identity provider' do
    it 'is invalid' do
      expect(response).to be_invalid
      expect(response.errors[:provider]).to include('must originate from registered identity provider.')
    end

    it 'is not trusted' do
      expect(response).not_to be_trusted
      expect(response.assertion).not_to be_trusted
    end
  end

  context 'when the issuer is a service provider' do
    before { registry.register(service_provider) }

    it_behaves_like 'a Response that is not from an identity provider'

    it 'refuses a signed Assertion' do
      assertion = Saml::Kit::Assertion.new(build_signed_assertion(acme), configuration: configuration)
      expect(assertion).to be_signed
      expect(assertion).to be_invalid
      expect(assertion.errors[:provider]).to contain_exactly('is unregistered.')
    end
  end

  context 'when the issuer is both and signs with the key of the identity provider' do
    before { registry.register(composite_of(identity_provider: acme, service_provider: initech)) }

    it 'is valid' do
      expect(registry.metadata_for(acme.entity_id)).to be_instance_of(Saml::Kit::CompositeMetadata)
      expect(response).to be_valid
    end
  end

  context 'when the issuer is both and signs with the key of the service provider' do
    before { registry.register(composite_of(identity_provider: initech, service_provider: acme)) }

    it 'is invalid' do
      expect(response).to be_invalid
      expect(response.errors.full_messages).to contain_exactly('Fingerprint is not registered.')
    end
  end

  context 'when the registry decorates metadata' do
    let(:registry) do
      Class.new(Saml::Kit::DefaultRegistry) do
        def metadata_for(issuer)
          SimpleDelegator.new(super)
        end
      end.new
    end

    it 'keeps a decorated identity provider' do
      expect(response).to be_valid
      expect(response.provider).to be_instance_of(SimpleDelegator)
    end

    context 'with a service provider' do
      before { registry.register(service_provider) }

      it_behaves_like 'a Response that is not from an identity provider'
    end
  end
end
