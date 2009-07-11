require File.join(File.dirname(__FILE__), '../lib/plain_record')

class Post
  include PlainRecord::Resource
  
  entry_in 'data/*/post.m'
  
  property :title
  text :summary
  text :content
end


class FilepathPost
  include PlainRecord::Resource
  
  entry_in 'data/**/*/post.m'
  
  virtual :category, in_filepath(1)
  virtual :name,     in_filepath(2)
  
  property :title
end

class Author
  include PlainRecord::Resource
  
  list_in 'data/authors/*.yml'
  
  property :login
  property :name
end

PlainRecord.root = File.dirname(__FILE__)

FIRST  = File.join(File.dirname(__FILE__), 'data/1/post.m')
SECOND = File.join(File.dirname(__FILE__), 'data/2/post.m')
THIRD  = File.join(File.dirname(__FILE__), 'data/3/post.m')
FIRST_POST  = Post.load_file(FIRST)
SECOND_POST = Post.load_file(SECOND)
THIRD_POST  = Post.load_file(THIRD)

INTERN = File.join(File.dirname(__FILE__), 'data/authors/intern.yml')
EXTERN = File.join(File.dirname(__FILE__), 'data/authors/extern.yml')

def model_methods(model)
    (model.instance_methods - Object.instance_methods -
        PlainRecord::Resource.instance_methods).map { |i| i.to_s }
end

Spec::Matchers.define :has_methods do |*methods|
  match do |model|
    model_methods(model).sort == methods.map! { |i| i.to_s }.sort
  end
end

class Definers
  def self.accessor
    proc { :accessor }
  end
  def self.writer
    proc { :writer }
  end
  def self.reader
    proc { :reader }
  end
  def self.none
    proc { nil }
  end
end
