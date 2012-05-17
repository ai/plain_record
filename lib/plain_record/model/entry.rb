=begin
Class with static methods for entry_in model class.

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
  module Model
    # Methods code, that is specific for entry storage, when each file contain
    # only one entry.
    module Entry
      def load_file(file)
        unless @loaded.has_key? file
          data, *texts = IO.read(file).split(/\n---[\t ]*\n/, @texts.length + 1)
          data = ::YAML.load(data)
          @loaded[file] = self.new(file, data, texts)
        end
        @loaded[file]
      end

      def each_entry(matcher = {})
        files(matcher).each do |file|
          yield load_file(file)
        end
      end

      def delete_entry(file, entry = nil)
        delete_file(file)
      end

      def move_entry(entry, from, to)
        if from
          @loaded.delete(from)
          delete_file(from)
        end
        @loaded[to] = entry
      end

      private

      def all_entries(matcher = {})
        files(matcher).map { |file| load_file(file) }
      end

      def entries_string(entry)
        entry.to_yaml + entry.texts.map{ |i| "---\n" + i }.join("\n")
      end
    end
  end
end
