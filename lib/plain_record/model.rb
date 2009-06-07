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

module PlainRecord
  # Static methods for model. Model class extend this class when Resource is
  # included into it. See Resource for instance methods of model.
  #
  # See also Model::Entry and Model::List for storage specific methods.
  module Model
    dir = Pathname(__FILE__).dirname.expand_path + 'model'
    autoload :Entry, (dir + 'entry').to_s
    autoload :List,  (dir + 'list').to_s
    
    include PlainRecord::Callbacks
    include PlainRecord::Filepath
    
    # Properties names.
    attr_reader :properties
    
    # Name of special properties with big text.
    attr_reader :texts
    
    # Storage type: +:entry+ or +:list+.
    attr_reader :storage
    
    # Content of already loaded files.
    attr_accessor :loaded
    
    # Load and return all entries in +file+.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def load_file(file); end
    
    # Call block on all entry, which is may be match for +matchers+. Unlike
    # <tt>all.each</tt> it use lazy file loading, so it is useful if you planing
    # to break this loop somewhere in the middle (for example, like +first+).
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def each_entry(matchers = {}); end
    
    # Delete +entry+ from +file+.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def delete_entry(file, entry = nil); end
      
    # Write all loaded entries to +file+.
    def save_file(file)
      if @loaded.has_key? file
        File.open(file, 'w') do |io|
          io.write entries_string(@loaded[file]).slice(5..-1)
        end
      end
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
      entries = all_entries(matchers)
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
        each_entry(matchers) { |i| return i if match(i, matchers) and block.call(i) }
      elsif matchers
        each_entry(matchers) { |i| return i if match(i, matchers) }
      elsif block_given?
        each_entry { |i| return i if block.call(i) }
      else
        each_entry { |i| return i }
      end
      nil
    end
    
    # Return all file list for models, which match for +matchers+.
    def files(matchers = {})
      Dir.glob(File.join(PlainRecord.root, path(matchers)))
    end
    
    # Return glob pattern to for files with entris, which is may be match for
    # +matchers+.
    def path(matchers = {})
      use_callbacks(:path, matchers) do
        @path
      end
    end
    
    private
    
    # Return all model entries, which is may be match for +matchers+.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def all_entries(matchers); end
    
    # Return string representation of +entries+ to write it to file.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def entries_string(entries); end
    
    # Delete file, cache and empty dirs in path.
    def delete_file(file)
      File.delete(file)
      @loaded.delete(file)
      
      path = Pathname(file).dirname
      root = Pathname(PlainRecord.root)
      until 2 != path.entries.length or path == root
        path.rmdir
        path = path.parent
      end
    end
    
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
    # Also add methods from <tt>Model::Entry</tt>.
    #
    #   entry_in 'content/*/post.m'
    def entry_in(path)
      @storage = :entry
      @path = path
      self.extend PlainRecord::Model::Entry
      @loaded = {}
      @texts = [] unless @texts
    end
    
    # Set glob +pattern+ for files with list of entries. Each file may contain
    # several entries, but you may have several files. All data will storage
    # in YAML, so you can’t define +text+.
    #
    # Also add methods from <tt>Model::List</tt>.
    #
    #   list_in 'content/authors.yml'
    def list_in(path)
      @storage = :list
      @path = path
      self.extend PlainRecord::Model::List
      @loaded = {}
    end
    
    # Add property to model with some +name+. It will be stored as YAML.
    #
    # You can provide your own define logic by +definers+. Definer Proc
    # will be call with property name in first argument and may return
    # +:accessor+, +:writer+ or +:reader+ this method create standard methods
    # to access to property.
    # 
    #   class Post
    #     include PlainRecord::Resource
    #
    #     entry_in 'posts/*/post.m'
    #
    #     property :title
    #   end
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
    # Note, that text is supported by only +entry_in+ models, which entry store
    # in separated files.
    #
    # == Example
    #
    # Model:
    # 
    #   class Post
    #     include PlainRecord::Resource
    #
    #     entry_in 'posts/*/post.m'
    #
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
      if :list == @storage
        raise ArgumentError, 'Text is supported by only entry_in models'
      end
      
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
