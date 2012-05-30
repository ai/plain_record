=begin
Extention to set to get field value from external file.

Copyright (C) 2012 Andrey “A.I.” Sitnik <andrey@sitnik.ru>,
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
  # Extention to set to get field value from external file.
  #
  #   class Post
  #     include PlainRecord::Resource
  #
  #     entry_in '*/post.md'
  #
  #     virtual :name, in_filepath(1)
  #     virtuel :text, file { |p| "#{p.name}/text.#{I18n.locale}.md" }
  #   end
  module File
    # Cache of field content before save.
    attr_accessor :unsaved_files

    # Return file pathname for fiel field.
    def field_filepath(field)
      path = self.class.fields_files[field]
      path = path.call(self) if path.is_a? Proc
      PlainRecord.root(path)
    end

    private

    # Define class variables and events in +klass+. It should be call once.
    def self.install(klass)
      klass.fields_files = { }

      klass.before :load do |entry|
        entry.unsaved_files = { }
      end

      klass.before :save do |entry|
        entry.unsaved_files.each_pair do |file, value|
          ::File.open(file, 'w') { |io| io << value; }
        end
        entry.unsaved_files = { }
      end
    end

    module Model

      # Field file paths.
      attr_accessor :fields_files

      private

      # Filter to load field value from file.
      def file(path = nil, &block)
        proc do |model, field, type|
          File.install(model) unless model.fields_files
          model.fields_files[field] = block_given? ? block : path

          model.add_accessors <<-EOS, __FILE__, __LINE__
            def #{field}
              path = field_filepath(:#{field})
              return @unsaved_files[path] if @unsaved_files.has_key? path
              return nil unless ::File.exists? path
              ::File.read(path)
            end

            def #{field}=(value)
              @unsaved_files[field_filepath(:#{field})] = value
            end
          EOS
        end
      end

    end
  end
end
