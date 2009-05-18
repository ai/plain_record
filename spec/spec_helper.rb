require File.join(File.dirname(__FILE__), '../lib/plain_record')

class Post
  include PlainRecord::Resource
  
  entry_in '*/post.m'
  
  property :title
end

PlainRecord.root = File.join(File.dirname(__FILE__), 'data')

FIRST  = File.join(File.dirname(__FILE__), 'data/1/post.m')
SECOND = File.join(File.dirname(__FILE__), 'data/2/post.m')

def model_methods(model)
    model.instance_methods - Object.instance_methods -
        PlainRecord::Resource.instance_methods
end

Spec::Matchers.define :has_methods do |*methods|
  match do |model|
    model_methods(model).sort == methods.sort
  end
end
Spec::Matchers.define :has_no_methods do |*methods|
  match do |model|
    model_methods(model).empty?
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
