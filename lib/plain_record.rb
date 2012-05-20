=begin
Main file to load all neccessary classes for Plain Record.

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

require 'pathname'
require 'yaml'

YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE

dir = Pathname(__FILE__).dirname.expand_path + 'plain_record'
require dir + 'version'
require dir + 'callbacks'
require dir + 'default'
require dir + 'filepath'
require dir + 'association_proxy'
require dir + 'associations'
require dir + 'type'
require dir + 'model'
require dir + 'resource'

module PlainRecord
  module Extra
    autoload :Git,  'plain_record/extra/git'
    autoload :I18n, 'plain_record/extra/i18n'
  end

  class << self
    # Set new root for Model#entry_in or Model#list_in.
    #
    # Note, that it add last slash to root path (<tt>/content</tt> will be saved
    # as <tt>/content/</tt>).
    def root=(value)
      value  = value.to_s
      value += File::SEPARATOR if File::SEPARATOR != value[-1..-1]
      @root  = value
    end

    # Return root for Model#entry_in or Model#list_in.
    #
    # If you set +path+ it will be added to root path.
    def root(path = '')
      File.join(@root, path)
    end
  end
end

if defined? Rails
  ActiveSupport.on_load(:after_initialize) do
    PlainRecord.root = Rails.root.join('data')
  end
end
