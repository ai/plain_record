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
  #   end
  module Resource
    class << self
      def included(base) #:nodoc:
        base.send :extend, Model
      end
    end
    
    # Properties values.
    attr_reader :data
    
    # File, where this object is stored.
    attr_reader :file
    
    # Create new model instance with +data+ from +file+.
    def initialize(file, data)
      @file = file
      @data = data
    end
    
    # Compare if its properties are equal.
    def eql?(other)
      return false unless other.kind_of?(self.class)
      @data == other.data
    end
    alias == eql?
  end
end
