require File.join(File.dirname(__FILE__), '../lib/plain_record')

class Post
  include PlainRecord::Resource

  entry_in 'data/*/post.md'

  field   :title
  text    :summary
  text    :content
end

class FilepathPost
  include PlainRecord::Resource

  entry_in 'data/**/*/post.md'

  virtual :category, in_filepath(1)
  virtual :name,     in_filepath(2)

  field   :title
end

class Author
  include PlainRecord::Resource

  list_in 'data/authors/*.yml'

  virtual :type, in_filepath(1)
  field   :login
  field   :name
end

PlainRecord.root = File.dirname(__FILE__)

FIRST  = File.join(File.dirname(__FILE__), 'data/1/post.md')
SECOND = File.join(File.dirname(__FILE__), 'data/2/post.md')
THIRD  = File.join(File.dirname(__FILE__), 'data/3/post.md')
FIRST_POST  = Post.load_file(FIRST)
SECOND_POST = Post.load_file(SECOND)
THIRD_POST  = Post.load_file(THIRD)

INTERN = File.join(File.dirname(__FILE__), 'data/authors/intern.yml')
EXTERN = File.join(File.dirname(__FILE__), 'data/authors/extern.yml')

def model_methods(model)
  (model.instance_methods  -
   Object.instance_methods -
   PlainRecord::Resource.instance_methods).map { |i| i.to_s }
end

RSpec::Matchers.define :has_methods do |*methods|
  match do |model|
    model_methods(model).sort == methods.map! { |i| i.to_s }.sort
  end
end

RSpec::Matchers.define :has_yaml do |expected|
  match do |actual|
    YAML.load(actual.string).should == expected
  end

  failure_message_for_should do |actual|
    "expected #{expected.inspect} to equal #{YAML.load(actual.string)}"
  end
end

def is_rbx
  defined?(RUBY_ENGINE) and RUBY_ENGINE == 'rbx'
end
