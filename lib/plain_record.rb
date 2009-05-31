=begin
Main file to load all neccessary classes for Plain Record.

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

require 'pathname'
require 'yaml'

dir = Pathname(__FILE__).dirname.expand_path + 'plain_record'
require dir + 'version'
require dir + 'callbacks'
require dir + 'model'
require dir + 'resource'

module PlainRecord
  class << self
    # Root of all file path in Model#entry_in.
    attr_accessor :root
  end
end
