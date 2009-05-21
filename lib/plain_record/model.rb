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
    
    # Return all entries, which is match for +matchers+ and return true on
    # +block+.
    #
    # Matchers is a Hash with property name in key and String or Regexp for
    # match in value.
    #
    #   Post.all(title: 'Post title')
    #   Post.all(title: /^Post/, summary: /cool/)
    #   Post.all { |post| 20 < Post.content.length }
    def all(matchers = {}, &block)
      entries = files.map { |file| load_file(file) }
      entries.delete_if { |i| not match(i, matchers) } if matchers
      entries.delete_if { |i| not block.call(i) } if block_given?
      entries
    end
    
    # Return first entry, which is match for +matchers+ and return true on
    # +block+.
    #
    # Matchers is a Hash with property name in key and String or Regexp for
    # match in value.
    #
    #   Post.first(title: 'Post title')
    #   Post.first(title: /^Post/, summary: /cool/)
    #   Post.first { |post| 2 < Post.title.length }
    def first(matchers = {}, &block)
      if matchers and block_given?
        each_entry { |i| return i if match(i, matchers) and block.call(i) }
      elsif matchers
        each_entry { |i| return i if match(i, matchers) }
      elsif block_given?
        each_entry { |i| return i if block.call(i) }
      else
        each_entry { |i| return i }
      end
      nil
    end
    
    # Call block on all entry. Unlike <tt>all.each</tt> it use lazy file
    # loading, so it is useful if you planing to break this loop somewhere in
    # the middle (for example, like +first+).
    def each_entry
      files.each do |file|
        yield load_file(file)
      end
    end
    
    # Return all model files.
    def files
      Dir.glob(File.join(PlainRecord.root, @path))
    end
    
    private
    
    # Match +object+ by +matchers+ to use in +all+ and +first+ methods.
    def match(object, matchers)
      matchers.each_pair do |key, matcher|
        result = if matcher.is_a? Regexp
          object.send(key) =~ matcher
        else
          object.send(key) == matcher
        end
        return false unless result
      end
      true
    end
    
    # Set glob +pattern+ for files with entry. Each file must contain one entry.
    # To set root for this path use +PlainRecord.root+.
    #
    #   entry_in 'content/*/post.m'
    def entry_in(path)
      @path = path
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
