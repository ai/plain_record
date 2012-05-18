=begin
Storage for one-to-many virtual associations.

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
  # Storage for one-to-many virtual associations. When new object will pushed,
  # proxy change it mapped properties.
  class AssociationProxy < Array
    # Model with association.
    attr_accessor :owner

    # Associations property name.
    attr_accessor :property

    # Create proxy for one-to-many virtual associations +property+ in +owner+
    # and put +array+ into it.
    def self.link(array, owner, property)
      proxy = new(array, owner, property)
      proxy.each { |i| proxy.link(i) }
      proxy
    end

    # Create proxy for one-to-many virtual associations +property+ in +owner+
    # with +array+ in value.
    def initialize(array, owner, property)
      @owner = owner
      @property = property
      super(array)
    end

    # Push new item in association and change it property by association map.
    def <<(obj)
      link(obj)
      super(obj)
    end

    # Change properties in +obj+ by association map.
    def link(obj)
      @owner.class.association_maps[@property].each do |from, to|
        obj.send(from.to_s + '=', @owner.send(to))
      end
    end
  end
end
