=begin
Module to add before/after hooks.

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
  # Callbacks are hooks that allow you to define methods to run before and
  # after some method, to change it logic.
  module Callbacks
    # Hash of class callbacks with field.
    attr_accessor :callbacks

    # Set block as callback before +events+. Callback with less +priority+ will
    # start earlier.
    #
    #   class File
    #     include PlainRecord::Callbacks
    #
    #     attr_accessor :name
    #     attr_accessor :content
    #
    #     def save
    #       use_callbacks(:save, self) do
    #         File.open(@name, 'w') { |io| io.puts @content }
    #       end
    #     end
    #   end
    #
    #   class NewFile < File
    #     before :save do |file|
    #       while File.exists? file.name
    #         file.name = 'another ' + file.name
    #       end
    #     end
    #
    #     before, :save do
    #       raise ArgumentError if 255 < @name.length
    #     end
    #   end
    def before(events, priority = 1, &block)
      Array(events).each do |event|
        add_callback(:before, event, priority, block)
      end
    end

    # Set block as callback after +events+. Callback with less +priority+ will
    # start earlier.
    #
    # After callbacks may change method return, which will be pass as first
    # argument for first callback. It return will be pass for next callback and
    # so on.
    #
    #   class Person
    #     include PlainRecord::Callbacks
    #
    #     def name
    #       use_callbacks(:name) do
    #         'John'
    #       end
    #     end
    #   end
    #
    #   class GreatPerson < Person
    #     after :name, 2 do |name|
    #       'Great ' + name
    #     end
    #
    #     after :name do |name|
    #       'The ' + name
    #     end
    #   end
    #
    #   GreatPerson.new.name #=> "The Great John"
    def after(events, priority = 1, &block)
      Array(events).each do |event|
        add_callback(:after, event, priority, block)
      end
    end

    # Call +before+ callbacks for +event+ with +params+. In your
    # code use more pretty +use_callbacks+ method.
    def call_before_callbacks(event, params)
      init_callbacks(event)
      @callbacks[:before][event].each do |before, priority|
        before.call(*params)
      end
    end

    # Call +before+ callbacks for +event+ with +params+. Callbacks can change 
    # +result+. In your code use more pretty +use_callbacks+ method.
    def call_after_callbacks(event, result, params)
      init_callbacks(event)
      @callbacks[:after][event].each do |after, priority|
        result = after.call(result, *params)
      end
      result
    end

    # Call before callback for +event+, run block and give it result to
    # after callbacks.
    #
    #   def my_save_method(entry)
    #     use_callbacks(:save, enrty) do
    #       entry.file.write
    #     end
    #   end
    def use_callbacks(event, *params, &block)
      call_before_callbacks(event, params)
      result = yield
      call_after_callbacks(event, result, params)
    end

    private

    # Backend for +before+ and +after+ method to add callback.
    def add_callback(type, event, priority, block)
      init_callbacks(event)

      @callbacks[type][event] << [block, priority]
      @callbacks[type][event].sort! { |a, b| a[1] <=> b[1] }
    end

    # Check and create Hash into +callbacks+ for +event+ if necessary.
    def init_callbacks(event)
      unless @callbacks
        @callbacks = { :before => { }, :after => { } }
      end
      @callbacks[:before][event] = [] unless @callbacks[:before][event]
      @callbacks[:after][event]  = [] unless @callbacks[:after][event]
    end
  end
end
