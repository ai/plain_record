# Plain Record

Plaint Record is a data persistence, which use human editable and readable plain
text files. It’s ideal for static generated sites, like blog or homepage.

If you want to write another static website generator, you don’t need to write
another file parser – you can use Plain Record.

Sponsored by [Evil Martians].

[Evil Martians]: http://evilmartians.com/

## How To

For example we will create simple blog storage with posts and comments.

1. Add Plain Record to your application Gemfile:

     ```ruby
    gem "plain_record"
     ```

2. Set storage root – dir, which will contain all data files:

     ```ruby
    PlainRecord.root = 'data/'
     ```

3. Create Post class, include `Plain::Resource` module, set glob pattern
   to posts files and define fields:

     ```ruby
    class Post
      include Plain::Resource

      entry_in '*/post.md'

      virtual :name,     in_filepath(1)
      virtual :comments, many(Comment)
      field   :title     default("Untitled")
      field   :tags
      text    :summary
      text    :content
    end
     ```

4. Create new post file `data/first/post.md`. Fields will be saved as
   YAML and text will be placed as plain text, which is separated by 3 dashes:

     ```
    title: My first post
    tags: test, first
    ---
    It is short post summary.
    ---
    And this is big big post text.
    In several lines.
     ```

5. Also you can use files with list of entries. For example, comments:

     ```ruby
    class Comment
      include Plain::Resource

      list_in '*/comments.yml'

      virtual :post_name, in_filepath(1)
      virtual :post,      one(Post)
      field   :author
      field   :comment
    end
     ```
   You can’t use text fields in list files.
6. List files is a just YAML array. For example, `data/first/comments.yml`:

     <pre><code>\- author: Anonymous
      comment: I like it!
   \- author: Friend
      comment: You first post it shit.</pre></code>

7. Get all post:

     ```ruby
    Post.all # will return array with our first post
     ```

8. Get specify enrties:

     ```ruby
    Comment.all(author: 'Anonymous')
    Post.all(title: /first/)
    Post.all { |i| i.tags.length == 2 }
     ```

9. To get one entry use `first` method, which also can take matchers. You can
   access for fields and text by methods with same name:

     ```ruby
    post = Post.first(title: /first/)
    post.file    #=> "data/first/post.md"
    post.name    #=> "first"
    post.title   #=> "My first post"
    post.tags    #=> ["test", "first"]
    post.summary #=> "It is short post summary."
     ```

10. You can also change and save entries:

      ```ruby
    post.title = 'First post'
    post.save
      ```

11. And delete it (with empty dirs in it file path):

      ```ruby
    post.destroy
      ```

## License

Plain Record is licensed under the GNU Lesser General Public License version 3.
See the LICENSE file or http://www.gnu.org/licenses/lgpl.html.

## Author

Andrey “A.I.” Sitnik <andrey@sitnik.ru> 
