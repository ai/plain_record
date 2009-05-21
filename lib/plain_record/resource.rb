=begin
Module to be included into model class.

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
  # Module to be included into model class. Contain instance methods. See
  # Model for class methods.
  #
  #   class Post
  #     include PlainRecord::Resource
  #     
  #     entry_in '/content/*/post.m'
  #     
  #     property :title
  #     text :summary
  #     text :content
  #   end
  module Resource
    class << self
      def included(base) #:nodoc:
        base.send :extend, Model
      end
    end
    
    # Properties values.
    attr_reader :data
    
    # Texts values.
    attr_reader :texts
    
    # File, where this object is stored.
    attr_reader :file
    
    # Create new model instance with YAML +data+ and +texts+ from +file+.
    def initialize(file, data, texts = [])
      @file = file
      @data = data
      @texts = texts
    end
    
    # Compare if its properties and texts are equal.
    def eql?(other)
      return false unless other.kind_of?(self.class)
      @data == other.data and @texts == @texts
    end
    alias == eql?
  end
end
