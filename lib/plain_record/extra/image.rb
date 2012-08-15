=begin
Extention to store images.

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

require 'fileutils'

module PlainRecord::Extra
  # Extention to store images.
  #
  # It make sense only with `entry_in` models. You can get created or modified
  # time from first or last git commit time.
  #
  # It is additional extention, so you need to include `PlainRecord::Extra::Git`
  # module to your model.
  #
  #   class User
  #     include PlainRecord::Resource
  #     include PlainRecord::Extra::Image
  #
  #     entry_in   "users/*.yml"
  #
  #     image_from do |user, field|
  #       "users/#{field}/#{user.name}.png"
  #     end
  #     image_url do |user, field, size|
  #       if size
  #         "users/#{user.name}/#{field}.#{size}.png"
  #       else
  #         "users/#{user.name}/#{field}.png"
  #       end
  #     end
  #
  #     virtual :name,   in_filepath(1)
  #     virtual :avatar, image(small: '32x32', big: '64x64')
  #     virtual :photo,  image
  #   end
  #
  #   # There are images at `data/users/avatar/ai.png` and
  #   # `data/users/photo/ai.png`
  #
  #   PlainRecord::Extra::Image.convert_images!
  #   user = User.first(name: 'ai')
  #
  #   user.photo.url  #=> "data/users/ai/photo.png"
  #   user.photo.file #=> "app/assets/images/data/users/ai/avatar.small.png"
  #   user.avatar(:small).url  #=> "data/users/ai/avatar.small.png"
  module Image
    class << self
      # Models, that used this extention.
      attr_accessor :included_in

      # Base of converted images.
      # Set to <tt>app/aseets/images/data</tt> in Rails.
      attr_accessor :dir

      # Base of converted images URL. Set to <tt>data/</tt> in Rails.
      attr_accessor :url

      def included(base)
        base.send :extend, Model
        self.included_in ||= []
        self.included_in << base
      end

      # Define class variables.
      def install(klass)
        klass.image_sizes = { }
      end

      def dir
        unless @dir
          raise ArgumentError,
               'You need to set `PlainRecord::Extra::Image.dir`'
        end
        @dir
      end

      def url
        unless @url
          raise ArgumentError,
               'You need to set `PlainRecord::Extra::Image.url`'
        end
        @url
      end

      # Delete all converted images.
      def clean_images!
        Dir.glob(File.join(self.dir, '**/*')) do |file|
          FileUtils.rm_r(file) if File.exists? file
        end
      end

      # Convert images in all models.
      def convert_images!
        clean_images!
        return unless included_in

        included_in.each do |model|
          model.all.each { |i| i.convert_images! }
        end
      end

    end

    # Convert all images to public dir.
    def convert_images!
      self.class.image_sizes.each_pair do |field, sizes|
        from = self.class.get_image_from(self, field)
        next unless File.exists? from

        if sizes.empty?
          to = self.class.get_image_file(self, field, nil)
          FileUtils.mkpath(File.dirname(to))
          FileUtils.cp(from, to)
        else
          require 'RMagick'
          source = ::Magick::Image.read(from).first
          sizes.each_pair do |name, size|
            to    = self.class.get_image_file(self, field, name)
            w, h  = size.split('x')
            image = source.resize(w.to_i, h.to_i)
            self.class.use_callbacks(:convert_image, self, to) do
              FileUtils.mkpath(File.dirname(to))
              image.write(to)
            end
          end
        end
      end
    end

    # Field value object with image paths and URL.
    class Data

      # Name of image size.
      attr_reader :size_name

      # Format of image size.
      attr_reader :size

      # Image width.
      attr_reader :width

      # Image height.
      attr_reader :height

      # Converted image URL.
      attr_reader :url

      # Converted image file.
      attr_reader :file

      # Original image file.
      attr_reader :original

      # Set image paths.
      def initialize(entry, field, size)
        @size_name = size
        @original  = entry.class.get_image_from(entry, field)

        if size
          @size = entry.class.image_sizes[field][size]
          unless @size
            raise ArgumentError, "Field `#{field}` doesn't have `#{size}` size"
          end
          @width, @height = @size.split('x').map { |i| i.to_i }
        end

        if size or entry.class.image_sizes[field].empty?
          @url  = entry.class.get_image_url(entry, field, size)
          @file = entry.class.get_image_file(entry, field, size)
        end
      end

      def exists?
        File.exists? @original
      end

    end

    module Model

      # Hash of image sizes.
      attr_accessor :image_sizes

      # Set source image path.
      def image_from(&block)
        @image_from = block
      end

      # Set relative image URL path from +image_base+.
      def image_url(&block)
        @image_url = block
      end

      # Get source image path.
      def get_image_from(entry, field)
        PlainRecord.root(@image_from.call(entry, field))
      end

      # Get converted image path.
      def get_image_file(entry, field, size)
        unless @image_url
          raise ArgumentError,
               "You need to set `image_url` in #{to_s} to calculate file path."
        end
        File.join(Image.dir, @image_url.call(entry, field, size))
      end

      # Get relative image URL path.
      def get_image_url(entry, field, size)
        unless @image_url
          raise ArgumentError,
               "You need to set `image_url` in #{to_s} to calculate file path."
        end
        File.join(Image.url, @image_url.call(entry, field, size))
      end

      private

      # Use pngcrush (you must install it in system) to optimize png images.
      #
      #   class User
      #     include PlainRecord::Resource
      #     include PlainRecord::Extra::Image
      #
      #     optimize_png
      #     …
      #   end
      def optimize_png
        after :convert_image do |result, entry, file|
          file = file.gsub(/([^A-Za-z0-9_\-\.,:\/@])/, "\\\\\\1")
          file = file.gsub(/(^|\/)\.?\.($|\/)/, '')
          return unless file =~ /\.png$/

          tmp = file + '.optimized'
          `pngcrush -rem gAMA -rem cHRM -rem iCCP -rem sRGB "#{file}" "#{tmp}"`
          FileUtils.rm(file)
          FileUtils.mv(tmp, file)
        end
      end

      # Filter to create field with image. You must set +image_from+.
      #
      # If you create Rails application you must set also +image_url+.
      # If you create web application with another web framework, you must
      # also redefine `image_url_to_path` or set `image_to`.
      #
      # If you create non-web application, you must set only `image_to`.
      #
      # You can set sizes hash (name to ImageMagick size) to convert images.
      def image(sizes = { })
        proc do |model, name, type|
          Image.install(model) unless model.image_sizes
          model.image_sizes[name] = sizes

          model.add_accessors <<-EOS, __FILE__, __LINE__
            def #{name}(size = nil)
              PlainRecord::Extra::Image::Data.new(self, :#{name}, size)
            end
          EOS
        end
      end

    end
  end
end
