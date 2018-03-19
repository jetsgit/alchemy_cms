module Alchemy
  class ElementSerializer < ActiveModel::Serializer
    self.root = false

    attributes :id,
      :name,
      :position,
      :page_id,
      :cell_id,
      :tag_list,
      :created_at,
      :updated_at,
      :ingredients,
      :content_ids

    def ingredients
      ingredient = []
      if object.definition['nestable_elements']
        object.nested_elements.each do |elemental|
          nested_val = elemental.contents.collect(&:serialize)
          ingredient << nested_val
        end
      else
        ingredient = object.contents.collect(&:serialize)
      end
      ingredient
    end
  end
end
