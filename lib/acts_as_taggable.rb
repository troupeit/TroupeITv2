module ActsAsTaggable
  module Taggable
    def self.included(base)
      base.field :tags, type: Array, default: []
      base.send :extend, TaggableClassMethods
    end

    module TaggableClassMethods
      def tagged_with(searchtag)
        obj = ActsAsTaggable::Tag.where({ name: searchtag }).collect { |x| x.tagged[0]["object_id"] }
      end

      def tagged_like(searchtag)
        search = Regexp.escape(searchtag)
        obj = ActsAsTaggable::Tag.where(name: /#{search}/i).collect { |x| x.tagged[0]["object_id"] }
      end
    end
  end

  module Tagger
    def tag(object, tags)
      return if tags.empty?
      deleted_tags =  object.tags.to_a - tags
      new_tags = tags - object.tags.to_a
      p new_tags
      p deleted_tags
      new_tags.each do |t|
        add_tag(object, t)
      end
      deleted_tags.each do |t|
        remove_tag(object, t)
      end
      object.tags = tags
      object.save
    end

    def add_tag(object, tag)
      a = ActsAsTaggable::Tag.find_or_initialize_by(name: tag, tagger_id: self.id, tagger_type: self.class.to_s)
      a.tagged = (a.tagged << { "object_class" => object.class.to_s, "object_id" => object.id }).uniq
      a.save
    end

    def remove_tag(object, tag)
      a = ActsAsTaggable::Tag.where(name: tag, tagger_id: self.id, tagger_type: self.class.to_s).first
      a.tagged = (a.tagged - [ { "object_class" => object.class.to_s, "object_id" => object.id } ]).uniq
      if a.tagged.count == 0
        a.destroy
      else
        a.save
      end
    end

    def tags
      ActsAsTaggable::Tag.where(tagger_id: self.id, tagger_type: self.class.to_s)
    end

    def tags_on(klasses)
      ActsAsTaggable::Tag.where(tagger_id: self.id, tagger_type: self.class.to_s).any_in("tagged.object_class" => klasses)
    end
  end

  class Tag
    include Mongoid::Document
    field :name, type: String
    field :tagged, type: Array, default: []
    field :tagger_id, type: String
    field :tagger_type, type: String
  end
end
