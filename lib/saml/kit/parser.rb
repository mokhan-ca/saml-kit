# frozen_string_literal: true

module Saml
  module Kit
    class Parser
      def self.parse(content)
        document = Nokogiri::XML(content, &:strict)
        raise Nokogiri::XML::SyntaxError, 'DOCTYPE is not allowed' if document.internal_subset

        document
      rescue Nokogiri::XML::SyntaxError => error
        Saml::Kit.logger.error(error)
        Nokogiri::XML::Document.new
      end

      # Creates a `{Saml::Kit::Metadata}` object from a raw XML [String].
      #
      # @param content [String] the raw metadata XML.
      # @return [Saml::Kit::Metadata] the metadata document or subclass.
      def metadata_from(content)
        document = self.class.parse(content)
        return unless document.at_xpath('/md:EntityDescriptor', XmlParseable::NAMESPACES)

        xpath = '/md:EntityDescriptor/md:SPSSODescriptor'
        sp = document.at_xpath(xpath, XmlParseable::NAMESPACES)
        xpath = '/md:EntityDescriptor/md:IDPSSODescriptor'
        idp = document.at_xpath(xpath, XmlParseable::NAMESPACES)
        if sp && idp
          Saml::Kit::CompositeMetadata.new(content)
        elsif sp
          Saml::Kit::ServiceProviderMetadata.new(content)
        elsif idp
          Saml::Kit::IdentityProviderMetadata.new(content)
        end
      end
    end
  end
end
