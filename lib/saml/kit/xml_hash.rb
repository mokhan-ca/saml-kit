# frozen_string_literal: true

module Saml
  module Kit
    module XmlHash
      class << self
        def from(element)
          ActiveSupport::XmlMini.with_backend(self) { Hash.from_xml(element) } || {}
        end

        def parse(element)
          element.nil? ? {} : { element.name => collapse(element) }
        end

        private

        def collapse(element)
          (attributes(element) + children(element) + texts(element))
            .group_by(&:first)
            .transform_values { |pairs| pairs.one? ? pairs.first.last : pairs.map(&:last) }
        end

        def attributes(element)
          namespaces = element.namespace_definitions.map { |x| [['xmlns', x.prefix], x.href] }
          attributes = element.attribute_nodes.map { |x| [[x.namespace&.prefix, x.name], x.value] }
          (namespaces + attributes).map { |name, value| [name.compact.join(':'), value] }
        end

        def children(element)
          element.element_children.map { |x| [x.name, collapse(x)] }
        end

        def texts(element)
          text = element.xpath('text()').map(&:content).join
          text.blank? && (text.empty? || element.element_children.any?) ? [] : [['__content__', text]]
        end
      end
    end
  end
end
