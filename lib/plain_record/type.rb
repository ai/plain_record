=begin
Extention to convert fields to special type.

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

require 'time'
require 'date'

module PlainRecord
  # Extention to set field type and convert value to it.
  #
  #   class Post
  #     include PlainRecord::Resource
  #
  #     entry_in '*/*/post.md'
  #
  #     field :title,   type(String)
  #     field :visits,  type(Integer)
  #     field :rating,  type(Float)
  #     field :created, type(Date)
  #     field :updated, type(Time)
  #   end
  #
  # You can add support for your classes. Just set parse and stringify
  # code to <tt>PlainRecord::Type</tt>:
  #
  #   PlainRecord::Type.parsers[Car]     = 'Car.parse(super)'
  #   PlainRecord::Type.stringifies[Car] = 'v.to_s'
  module Type

    private

    def type(klass)
      proc do |model, field, type|
        model.add_accessors <<-EOS, __FILE__, __LINE__
          def #{field}
            #{Type.parsers[klass]}
          end
          def #{field}=(v)
            super(#{Type.stringifies[klass]})
          end
        EOS
      end
    end

    class << self
      # Hash of class to string of parse code.
      attr_accessor :parsers

      # Hash of class to string of stringify code.
      attr_accessor :stringifies
    end

    Type.parsers = {
      String  => 'super ? super.to_s : nil',
      Integer => 'super ? super.to_i : nil',
      Float   => 'super ? super.to_f : nil',
      Time    => 'super ? Time.parse(super) : nil',
      Date    => 'super ? Date.parse(super) : nil'
    }
    Type.stringifies = {
      String  => 'v ? v.to_s : v',
      Integer => 'v ? v.to_i : v',
      Float   => 'v ? v.to_f : v',
      Time    => 'v ? v.strftime("%Y-%m-%d %H:%M:%S %Z") : v',
      Date    => 'v ? v.strftime("%Y-%m-%d") : v'
    }
  end
end
