=begin
Extention to store or have link to another model.

Copyright (C) 2009 Andrey “A.I.” Sitnik <andrey@sitnik.ru>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module PlainRecord
  # Extention for model to store or have link to another model. There is two
  # type of association.
  #
  # == Virtual property
  # In +virtual+ method this definer create only _link_ to another model. When
  # you try to use this virtual property, model will find association object by
  # rules in +map+.
  #
  # Rules in +map+ is only Hash with model properties in key and association
  # properties in value. For example, if model contain +name+ property and
  # association must have +post_name+ with same value, +map+ will be 
  # <tt>{ :name => :post_name }</tt>.
  #
  # If you didn’t set +map+ definer will try to find it automatically:
  # it will find in model and association class all property pairs, what have
  # name like +property+ → <tt>model</tt>_<tt>property</tt>. For example,
  # if model +Post+ have property +name+ and +Comment+ have +post_name+, you
  # may not set +map+ – definer will find it automatically.
  #
  #   class Review
  #     include PlainRecord::Resource
  #
  #     entry_in 'reviews/*.md'
  #
  #     virtual  :author, one(Author)
  #     property :author_login
  #     text     :review
  #   end
  #
  #   class Author
  #     include PlainRecord::Resource
  #
  #     list_in 'authors.yml'
  #
  #     virtual  :reviews, many(Review)
  #     property :login
  #     property :name
  #   end
  #
  # == Real property
  # If you will use this definer in +property+ method, association object data
  # will store in you model file. For example model:
  #
  #   class Movie
  #     include PlainRecord::Resource
  #
  #     property :title
  #     property :genre
  #     property :release_year
  #   end
  #
  #   class Tag
  #     include PlainRecord::Resource
  #     property :name
  #   end
  #
  #   class Review
  #     include PlainRecord::Resource
  #
  #     entry_in 'reviews/*.md'
  #
  #     property :author
  #     property :movie, one(Movie)
  #     property :tags, many(Tag)
  #     text     :review
  #   end
  #
  # will be store as:
  #
  #   author: John Smith 
  #   movie:
  #     title: Watchmen
  #     genre: action
  #     release_year: 2009
  #   tags:
  #   - name: Great movies
  #   - name: Comics
  #   ---
  #   Movie is great!
  module Associations
    # Hash with map for virtual associations.
    attr_accessor :association_maps

    # Hash with cached values for virtual associations.
    attr_accessor :association_cache

    private

    # Return definer for one-to-one association with +klass+. Have different
    # logic in +property+ and +virtual+ methods.
    def one(klass, map = { })
      proc do |property, caller|
        if :property == caller
          Associations.define_real_one(self, property, klass)
          :accessor
        elsif :virtual == caller
          map = Associations.map(self, klass, "#{property}_") if map.empty?
          Associations.define_link_one(self, klass, property, map)
          nil
        else
          raise ArgumentError, "You couldn't create association property" +
                               " #{property} by text creator"
        end
      end
    end

    # Return definer for one-to-many or many-to-many association with +klass+.
    # Have different login in +property+ and +virtual+ methods.
    def many(klass, prefix = nil, map = { })
      proc do |property, caller|
        if :property == caller
          Associations.define_real_many(self, property, klass)
          :accessor
        elsif :virtual == caller
          unless prefix
            prefix = self.to_s.gsub!(/[A-Z]/, '_\0')[1..-1].downcase + '_'
          end
          map = Associations.map(klass, self, prefix) if map.empty?
          Associations.define_link_many(self, klass, property, map)
          nil
        else
          raise ArgumentError, "You couldn't create association property" +
                               " #{property} by text creator"
        end
      end
    end

    class << self
      # Define, that +property+ in +klass+ contain in file data from +model+.
      def define_real_one(klass, property, model)
        name = property.to_s
        klass.after :load do |result, entry|
          entry.data[name] = model.new(entry.file, entry.data[name])
          result
        end
        klass.before :save do |entry|
          model.call_before_callbacks(:save, [entry.data[name]])
          entry.data[name] = entry.data[name]
        end
        klass.after :save do |result, entry|
          entry.data[name] = model.new(entry.file, entry.data[name])
          model.call_after_callbacks(:save, nil, [entry.data[name]])
          result
        end
      end

      # Define, that +property+ in +klass+ contain in file array of data from
      # +model+ objects.
      def define_real_many(klass, property, model)
        name = property.to_s
        klass.after :load do |result, entry|
          if entry.data[name].is_a? Enumerable
            entry.data[name].map! { |i| model.new(entry.file, i) }
          else
            entry.data[name] = []
          end
          result
        end
        klass.before :save do |entry|
          if entry.data[name].empty?
            entry.data.delete(name)
          else
            entry.data[name].map! do |obj|
              model.call_before_callbacks(:save, [obj])
              obj.data
            end
          end
        end
        klass.after :save do |result, entry|
          entry.data[name].map! { |i| model.new(entry.file, i) }
          entry.data[name].each do |i|
            model.call_after_callbacks(:save, nil, [i])
          end
          result
        end
      end

      # Find properties pairs in +from+ and +to+ models, witch is like
      # <tt>prefix</tt>_<tt>from</tt> → +to+.
      #
      # For example, if Comment contain +post_name+ property and Post contain
      # +name+:
      #
      #   Associations.map(Comment, Post, :post) #=> { :post_name => :name }
      def map(from, to, prefix)
        from_fields = (from.properties + from.virtuals).map { |i| i.to_s }
        mapped = { }
        (to.properties + to.virtuals).each do |to_field|
          from_field = prefix + to_field.to_s
          if from_fields.include? from_field
            mapped[from_field.to_sym] = to_field
          end
        end
        mapped
      end

      # Define that virtual property +name+ in +klass+ contain link to +model+
      # witch is finded by +map+.
      def define_link_one(klass, model, name, map)
        klass.association_cache ||= { }
        klass.association_maps  ||= { }
        klass.association_maps[name] = map

        klass.class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            unless self.class.association_cache[:#{name}]
              search = Hash[
                self.class.association_maps[:#{name}].map do |from, to|
                  [to, send(from)]
                end]
              self.class.association_cache[:#{name}] = #{model}.first(search)
            end
            self.class.association_cache[:#{name}]
          end
          def #{name}=(value)
            self.class.association_maps[:#{name}].each do |from, to|
              value.send(to.to_s + '=', send(from))
            end
            self.class.association_cache[:#{name}] = value
          end
        EOS
      end

      # Define that virtual property +name+ in +klass+ contain links to +model+
      # witch are finded by +map+.
      def define_link_many(klass, model, name, map)
        klass.association_cache ||= { }
        klass.association_maps  ||= { }
        klass.association_maps[name] = map

        klass.class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            unless self.class.association_cache[:#{name}]
              search = Hash[
                self.class.association_maps[:#{name}].map do |from, to|
                  [from, send(to)]
                end]
              self.class.association_cache[:#{name}] = AssociationProxy.new(
                  #{model}.all(search), self, :#{name})
            end
            self.class.association_cache[:#{name}]
          end
          def #{name}=(values)
            self.class.association_cache[:#{name}] = AssociationProxy.link(
                values, self, :#{name})
          end
        EOS
      end
    end
  end
end
