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
  # You can set your callbacks before and after some methods/events:
  # * <tt>path(matchers)</tt> – return file names for model which is match for
  #   matchers;
  # * <tt>load(enrty)</tt> – load or create new entry;
  # * <tt>destroy(entry)</tt> – delete entry;
  # * <tt>save(entry)</tt> – write entry to file.
  # See PlainRecord::Callbacks for details.
  #
  # You can define properties  from entry file path, by +in_filepath+ definer.
  # See PlainRecord::Filepath for details.
  #
  #   class Post
  #     include PlainRecord::Resource
  #
  #     entry_in 'content/*/post.m'
  #
  #     before :save do |enrty|
  #       entry.title = Time.now.to.s unless entry.title
  #     end
  #
  #     virtual :name, in_filepath(1)
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
    attr_accessor :file

    # Create new model instance with YAML +data+ and +texts+ from +file+.
    def initialize(file = nil, data = {}, texts = [])
      self.class.use_callbacks(:load, self) do
        texts, data = data, nil if data.is_a? Array
        data,  file = file, nil if file.is_a? Hash

        @file  = file
        @data  = data
        @texts = texts
      end
    end

    # Set path to entry storage. File should be in <tt>PlainRecord.root</tt> and
    # can be relative.
    def file=(value)
      if PlainRecord.root != value.slice(0...PlainRecord.root.length)
        value = PlainRecord.root(value)
      end

      if @file != value
        self.class.move_entry(self, @file, value)
        @file = value
      end
    end

    # Return relative path to +file+ from <tt>PlainRecord.root</tt>.
    def path
      return nil unless @file
      @file.slice(PlainRecord.root.length..-1)
    end

    # Save entry to file. Note, that for in_list models it also save all other
    # entries in file.
    def save
      self.class.use_callbacks(:save, self) do
        unless @file
          unless self.class.path =~ /[\*\[\?\{]/
            self.file = self.class.path
          else
            raise ArgumentError, "There isn't file to save entry. " +
                                 "Set filepath properties or file."
          end
        end

        self.class.save_file(@file)
      end
    end

    # Delete current entry and it file if there isn’t has any other entries.
    def destroy
      self.class.use_callbacks(:destroy, self) do
        self.class.delete_entry(@file, self)
      end
    end

    # Return string of YAML representation of entry +data+.
    def to_yaml(opts = {})
      @data.to_yaml(opts)
    end

    # Compare if its properties and texts are equal.
    def eql?(other)
      return false unless other.kind_of?(self.class)
      @file == other.file and @data == other.data and @texts == @texts
    end
    alias == eql?
  end
end
