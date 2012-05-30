=begin
Ruby on Rails integration.

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

ActiveSupport.on_load(:after_initialize) do
  PlainRecord.root = Rails.root.join('data')
  PlainRecord::Extra::Image.dir = Rails.root.join('app/assets/images/data/')
  PlainRecord::Extra::Image.url = 'data/'
end

module PlainRecord::RailsController
  private
  def plain_record_convert_images
    Dir.glob(Rails.root.join('app/models/**/*.rb')) { |i| require_dependency i }
    PlainRecord::Extra::Image.convert_images!
  end
end

if Rails.env.development?
  ActionController::Base.send(:include, PlainRecord::RailsController)
  ActionController::Base.send(:before_filter, :plain_record_convert_images)
end
