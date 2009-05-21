=begin
Class with static methods for list_in model class.

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
    # Methods code, that is specific for list storage, when each file contain
    # only several entry.
    module List
      def load_file(file)
        unless @loaded[file]
          data = ::YAML.load_file(file)
          @loaded[file] = data.map { |i| self.new(file, i) }
        end
        @loaded[file]
      end
      
      def each_entry
        files.each do |file|
          load_file(file).each do |entry|
            yield entry
          end
        end
      end
      
      private
      
      def all_entries
        files.map { |file| load_file(file) }.flatten
      end
    end
  end
end
