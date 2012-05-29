=begin
Extention to get field value depend on user locale.

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

module PlainRecord::Extra
  # Extention to get field value depend on user locale.
  #
  # You can’t use this filter for texts, because you need to set hash of
  # language code to translated string. For example in YAML fiels:
  #
  # title:
  #   en: Title
  #   ru: Заголовок
  #
  # Then just set filter to `virtual` or `field`.
  #
  #   class Post
  #     include PlainRecord::Resource
  #     include PlainRecord::Extra::I18n
  #
  #     field :title, i18n
  #   end
  #
  # By default, this filter will use current locale from Rails I18n or R18n,
  # if they are defined. If you need to take locale from another space, just
  # redefine `locale` model method.
  #
  #   class Post
  #     def locale
  #       ENV['locale']
  #     end
  #   end
  module I18n
    def self.included(base)
      base.send :extend, Model
    end

    # Return default locale. By default it look in R18n or Rails I18n.
    # Redefine it if you need another logic.
    def locale
      if defined? ::R18n::I18n
        ::R18n.get
      elsif defined? ::I18n
        ::I18n.locale
      else
        raise "Can't find R18n or I18n. Redefine `locale` method."
      end
    end

    # Return locale code depend on autodetected I18n library.
    def locale_code
      code = locale
      if defined? R18n::I18n and code.is_a? R18n::I18n
        code.locale.code
      elsif code.is_a? Symbol
        code.to_s
      else
        code
      end
    end

    # Return subvalue of `hash` depend on user locale from `locale` method.
    #
    # If R18n or Rails I18n is loaded it will use them logic to translate.
    def get_translation(name, hash, *params)
      return hash unless hash.is_a? Hash
      path = "#{self.class.name}##{name}"

      if defined? R18n::I18n and locale.is_a? R18n::I18n
        r18n = locale
        r18n.locales.each do |lang|
          code = lang.code
          next unless hash.has_key? code

          result = hash[code]
          type   = self.class.fields_i18n_types[name.to_sym]

          if type
            return r18n.filter_list.
              process(:all, type, result, lang, path, params)
          elsif result.is_a? String
            result = ::R18n::TranslatedString.new(result, lang, path)
            return r18n.filter_list.process_string(:all, result, path, params)
          else
            return result
          end
        end

        ::R18n::Untranslated.new("#{self.class.name}#", name,
                                 locale.locale, locale.filter_list)

      elsif defined? ::I18n
        hash[locale.to_s]

      else
        hash[locale]
      end
    end

    module Model
      # R18n type for fields.
      attr_accessor :fields_i18n_types

      private

      # Filter to return value depend on model locale.
      #
      # If you use R18n, you can set `type` to specify filters.
      #
      #   field comment_count, i18n('pl')
      def i18n(r18n_type = nil)
        proc do |model, field, type|
          if :text == type
            raise ArgumentError, "You can't set i18n filter for text"
          end

          model.fields_i18n_types ||= { }
          model.fields_i18n_types[field] = r18n_type if r18n_type

          model.send :alias_method, "untraslated_#{field}",  field
          model.send :alias_method, "untraslated_#{field}=", "#{field}="

          model.add_accessors <<-EOS, __FILE__, __LINE__
            def #{field}(*params)
              get_translation("#{field}", super, *params)
            end
            def #{field}=(value)
              if untraslated_#{field}
                untraslated_#{field}[locale_code] = value
              else
                super({ locale_code => value })
              end
            end
          EOS
        end
      end
    end
  end
end
