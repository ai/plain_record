=begin
Class with static methods for model class.

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

require 'yaml'

module PlainRecord
  # Static methods for model. Model class extend this class when Resource is
  # included into it. See Resource for instance methods of model.
  module Model
    
    # Properties names.
    attr_reader :properties
    
    # Name of special properties with big text.
    attr_reader :texts
    
    # Load and return all entries in +file+.
    def load_file(file)
      data, *texts = IO.read(file).split(/\n---[\t ]*\n/, @texts.length + 1)
      data = ::YAML.load(data)
      class_exec { new(file, data, texts) }
    end
    
    # Return all entries.
    def all
      Dir.glob(path).map { |file| load_file(file) }
    end
    
    private
    
    # Set glob +pattern+ for files with entry. Each file contain one entry.
    #
    #   entry_in 'content/*/post.m'
    def entry_in(pattern)
      @path = pattern
    end
    
    # Return glob +pattern+ for files with entry.
    def path
      File.join(PlainRecord.root, @path)
    end
    
    # Add property to model with some +name+. It will be stored as YAML.
    #
    # You can provide your own define logic by +definers+. Definer Proc
    # will be call with property name in first argument and may return
    # +:accessor+, +:writer+ or +:reader+ this method create standard methods
    # to access to property.
    def property(name, *definers)
      @properties ||= []
      @properties << name
      
      accessors = call_definers(definers, name)
      
      if accessors[:reader]
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            @data['#{name}']
          end
        EOS
      end
      if accessors[:writer]
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}=(value)
            @data['#{name}'] = value
          end
        EOS
      end
    end
    
    # Add special property with big text (for example, blog entry content). It
    # will stored after 3 dashes (<tt>---</tt>).
    #
    # You can provide your own define logic by +definers+. Definer Proc
    # will be call with property name in first argument and may return
    # +:accessor+, +:writer+ or +:reader+ this method create standard methods
    # to access to property.
    #
    # == Example
    #
    # Model:
    # 
    #   class Post
    #     property :title
    #     text :summary
    #     text :content
    #   end
    # 
    # File:
    # 
    #   title: Post title
    #   ---
    #   Post summary
    #   ---
    #   Post text
    def text(name, *definers)
      @texts ||= []
      @texts << name
      number = @texts.length - 1
      
      accessors = call_definers(definers, name)
      
      if accessors[:reader]
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            @texts[#{number}]
          end
        EOS
      end
      if accessors[:writer]
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}=(value)
            @texts[#{number}] = value
          end
        EOS
      end
    end
    
    # Call +definers+ for property with +name+ and return accessors, which will
    # be created as standart by +property+ or +text+ method.
    def call_definers(definers, name)
      accessors = {:reader => true, :writer => true}
      
      definers.each do |definer|
        access = definer.call(name)
        if :writer == access or access.nil?
          accessors[:reader] = false
        end
        if :reader == access or access.nil?
          accessors[:writer] = false
        end
      end
      
      accessors
    end
  end
end
