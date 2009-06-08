=begin
Extention to get property from entry file path.

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
  # Extention to get properties from enrty file path. For example, your blog
  # post may stored in <tt>_name_/post.m</tt>, and post model will have +name+
  # property. Also if you set name property to Model#first or Model#all method,
  # they will load entry directly only by it file.
  #
  # To define filepath property:
  # 1. Use <tt>*</tt> or <tt>**</tt> pattern in model path in +enrty_in+ or
  #    +list_in+.
  # 2. In +property+ method use <tt>in_filepath(i)</tt> definer after name with
  #    <tt>*</tt> or <tt>**</tt> number (start from 1).
  # 
  # Define filepath property only after +entry_in+ or +list_in+ call.
  # 
  #   class Post
  #     include PlainRecord::Resource
  #     
  #     entry_in '*/*/post.m'
  #     
  #     property :category, in_filepath(1)
  #     property :name,     in_filepath(1)
  #     …
  #   end
  #   
  #   superpost = Post.new
  #   superpost.name = 'superpost'
  #   superpost.category = 'best/'
  #   superpost.save                     # Save to best/superpost/post.m
  #   
  #   bests = Post.all(category: 'best') # Look up only in best/ dir
  module Filepath
    attr_accessor :filepath_properties
    attr_accessor :filepath_regexp
    
    private
    
    # Return definer for filepath property for +number+ <tt>*</tt> or
    # <tt>**</tt> pattern in path.
    def in_filepath(number)
      proc do |property|
        PlainRecord::Filepath.define_property(self, property, number)
      end
    end
    
    class << self
      # Define class variables and events in +klass+. It should be call once on
      # same class after +entry_in+ or +list_in+ call.
      def install(klass)
        klass.filepath_properties = {}
        
        path = Regexp.escape(klass.path).gsub(/\\\*\\\*(\/|$)/, '(.*)').
                                          gsub('\\*', '([^/]+)')
        klass.filepath_regexp = Regexp.new(path)
          
        klass.class_eval do
          attr_accessor :filepath_data
        end
        
        klass.after :load do |result, entry|
          if entry.path
            data = klass.filepath_regexp.match(entry.path)
            entry.filepath_data = {}
            klass.filepath_properties.each_pair do |number, name|
              entry.filepath_data[name] = data[number]
            end
          else
            entry.filepath_data = {}
            klass.filepath_properties.each_value do |name|
              entry.filepath_data[name] = entry.data[name]
              entry.data.delete(name)
            end
          end
          result
        end
        
        klass.after :path do |path, matchers|
          i = 0
          path.gsub /(\*\*(\/|$)|\*)/ do |pattern|
            i += 1
            property = klass.filepath_properties[i]
            unless matchers[property].is_a? Regexp or matchers[property].nil?
              matchers[property]
            else
              pattern
            end
          end
        end
        
        klass.before :save do |entry|
          unless entry.file
            path = klass.path(entry.filepath_data)
            entry.file = path unless path =~ /[\*\[\?\{]/
          end
        end
      end
      
      # Define in +klass+ filepath property with +name+ for +number+ <tt>*</tt>
      # or <tt>**</tt> pattern in path.
      def define_property(klass, name, number)
        unless klass.filepath_properties
          install(klass)
        end
        
        klass.filepath_properties[number] = name
        
        klass.class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            @filepath_data[:#{name}]
          end
          def #{name}=(value)
            @filepath_data[:#{name}] = value
          end
        EOS
      end
    end
  end
end