=begin
Extention to get time from git commits of model file.

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
  # Extention to get time from git commits of model file.
  #
  # It make sense only with `entry_in` models. You can get created or modified
  # time from first or last git commit time.
  #
  # It is additional extention, so you need to include `PlainRecord::Git`
  # module to your model.
  #
  #   class Post
  #     include PlainRecord::Resource
  #     include PlainRecord::Git
  #
  #     virtual :created_at, git_created_time
  #     virtual :updated_at, git_modify_time
  #   end
  module Git
    class << self
      def included(base)
        base.send :extend, Model
      end
    end

    # Return time of first commit of model file (created time).
    #
    # If file isn’t commited yet, it will return `Time.now`.
    def first_git_commit
      return Time.now unless file
      times = `git log --reverse --date=iso --pretty=format:%cD #{file}`
      time  = times.split("\n").first
      time ? Time.parse(time) : Time.now
    end

    # Return time of last commit of model file (modified time).
    #
    # If file isn’t commited yet, it will return `Time.now`.
    def last_git_commit
      return Time.now if file.nil? or git_uncommitted?
      time = `git log -1 --date=iso --pretty=format:%cD #{file}`
      time ? Time.parse(time) : Time.now
    end

    # If file have changes, that is not commited yet.
    def git_uncommitted?
      not `git status -s #{file}`.empty?
    end

    module Model
      # Filter to set default value to time of last file git commit.
      # If file is not commited or has changes, filter will return `Time.now`.
      def git_modified_time
        proc do |model, name, type|
          model.add_accessors <<-EOS, __FILE__, __LINE__
            def #{name}
              super || last_git_commit
            end
          EOS
        end
      end

      # Filter to set default value to time of first file git commit.
      # If file is not commited or has changes, filter will return `Time.now`.
      def git_created_time
        proc do |model, name, type|
          model.add_accessors <<-EOS, __FILE__, __LINE__
            def #{name}
              super || first_git_commit
            end
          EOS
        end
      end
    end
  end
end
