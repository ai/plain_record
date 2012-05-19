=begin
Class with static methods for model class.

Copyright (C) 2009 Andrey “A.I.” Sitnik <andrey@sitnik.ru>,
sponsored by Evil Martians.

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
    include PlainRecord::Associations

    # YAML fields names.
    attr_accessor :fields

    # Name of special fields with big text.
    attr_accessor :texts

    # Fields names with dynamic value.
    attr_accessor :virtuals

    # Storage type: +:entry+ or +:list+.
    attr_reader :storage

    # Content of already loaded files.
    attr_accessor :loaded

    # Named modules, created by +add_accessors+.
    attr_accessor :accessors_modules

    def self.extended(base) #:nodoc:
      base.fields   = []
      base.virtuals = []
      base.texts    = []
      base.loaded   = { }
      base.accessors_modules = { }
    end

    # Load and return all entries in +file+.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def load_file(file); end

    # Call block on all entry, which is may be match for +matchers+. Unlike
    # <tt>all.each</tt> it use lazy file loading, so it is useful if you planing
    # to break this loop somewhere in the middle (for example, like +first+).
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def each_entry(matchers = { }); end

    # Delete +entry+ from +file+.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def delete_entry(file, entry = nil); end

    # Move +entry+ from one file to another.
    #
    # See method code in <tt>Model::Entry</tt> or <tt>Model::List</tt>.
    def move_entry(entry, from, to); end

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
    # Matchers is a Hash with field name in key and String or Regexp for
    # match in value.
    #
    #   Post.all(title: 'Post title')
    #   Post.all(title: /^Post/, summary: /cool/)
    #   Post.all { |post| 20 < Post.content.length }
    def all(matchers = { }, &block)
      entries = all_entries(matchers)
      entries.delete_if { |i| not match(i, matchers) } if matchers
      entries.delete_if { |i| not block.call(i) }      if block_given?
      entries
    end

    # Return first entry, which is match for +matchers+ and return true on
    # +block+.
    #
    # Matchers is a Hash with field name in key and String or Regexp for
    # match in value.
    #
    #   Post.first(title: 'Post title')
    #   Post.first(title: /^Post/, summary: /cool/)
    #   Post.first { |post| 2 < Post.title.length }
    def first(matchers = { }, &block)
      if matchers and block_given?
        each_entry(matchers) do |i|
          return i if match(i, matchers) and block.call(i)
        end
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
    def files(matchers = { })
      Dir.glob(PlainRecord.root(path(matchers)))
    end

    # Return glob pattern to for files with entris, which is may be match for
    # +matchers+.
    def path(matchers = { })
      use_callbacks(:path, matchers) do
        @path
      end
    end

    # Create new anonymous module and include in model.
    #
    # You can set +name+ and it will old module, if it was created with same
    # name.
    #
    # It is helper to create model fields accessors and filters for it with
    # +super+ support.
    #
    #   add_accessors.module_eval <<-EOS, __FILE__, __LINE__
    #     def #{name}
    #       @data['#{name}']
    #     end
    #   EOS
    def add_accessors(name = nil)
      if name and @accessors_modules.has_key? name
        @accessors_modules[name]
      else
        mod = Module.new
        if name
          @accessors_modules[name] = mod
        end
        include mod
        mod
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
    #   entry_in 'content/*/post.md'
    def entry_in(path)
      @storage = :entry
      @path = path
      self.extend PlainRecord::Model::Entry
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
    end

    # Add virtual field with some +name+ to model. It value willn’t be in
    # file and will be calculated dynamically.
    #
    # You _must_ provide your own define logic by +definers+. Definer Proc
    # will be call with models class as first argument, field name as second and
    # field type as second.
    #
    #   class Post
    #     include PlainRecord::Resource
    #
    #     entry_in 'posts/*/post.md'
    #
    #     virtual :name, in_filepath(1)
    #   end
    def virtual(name, *definers)
      @virtuals ||= []
      @virtuals << name

      if definers.length.zero?
        raise ArgumentError, 'You must provide you own accessors for virtual ' +
                             "field #{name}"
      end

      definers.each { |i| i.call(self, name, :virtual) }
    end

    # Add field with some +name+ to model. It will be stored as YAML.
    #
    # You may provide your own define logic by +definers+. Definer Proc
    # will be call with models class as first argument, field name as second and
    # field type as second.
    #
    #   class Post
    #     include PlainRecord::Resource
    #
    #     entry_in 'posts/*/post.md'
    #
    #     field :title
    #   end
    def field(name, *definers)
      @fields ||= []
      @fields  << name

      add_accessors(:main).module_eval <<-EOS, __FILE__, __LINE__
        def #{name}
          @data['#{name}']
        end
        def #{name}=(value)
          @data['#{name}'] = value
        end
      EOS

      definers.each { |i| i.call(self, name, :field) }
    end

    # Add special field with big text (for example, blog entry content).
    # It will stored after 3 dashes (<tt>---</tt>).
    #
    # You may provide your own define logic by +definers+. Definer Proc
    # will be call with models class as first argument, field name as second and
    # field type as second.
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
    #     entry_in 'posts/*/post.md'
    #
    #     field :title
    #     text  :summary
    #     text  :content
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

      add_accessors(:main).module_eval <<-EOS, __FILE__, __LINE__
        def #{name}
          @texts[#{number}]
        end
        def #{name}=(value)
          @texts[#{number}] = value
        end
      EOS

      definers.each { |i| i.call(self, name, :text) }
    end
  end
end
