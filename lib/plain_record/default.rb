=begin
Extention to set default value for field.

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
  # Extention to set default value for field.
  #
  #   class Post
  #     include PlainRecord::Resource
  #
  #     entry_in '*/*/post.md'
  #
  #     virtual :category, default('uncategorized')
  #     …
  #   end
  #
  #   post = Post.new
  #   post.category       #=> "uncategorized"
  #   post.category = "a"
  #   post.category       #=> "a"
  module Default
    attr_accessor :default_values

    private

    def default(value)
      proc do |model, field, type|
        Default.install(model) unless model.default_values
        model.default_values[field] = value

        model.add_accessors <<-EOS, __FILE__, __LINE__
          def #{field}
            super || self.class.default_values[:#{field}]
          end
        EOS
      end
    end

    class << self
      # Define class variables and events in +klass+. It should be call once on
      # same class after +entry_in+ or +list_in+ call.
      def install(klass)
        klass.default_values = { }
      end
    end
  end
end
