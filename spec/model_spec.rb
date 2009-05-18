require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Model do
  
  it "should define property" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one
    end
    
    klass.properties.should == [:one]
    object = klass.new({'one' => 1})
    object.one.should == 1
    object.one = 2
    object.one.should == 2
  end
  
  it "should call definer" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one, Definers.accessor
      property :two, Definers.reader
      property :three, Definers.writer
      property :four, Definers.none
    end
    klass.should has_methods(:one, :'one=', :'three=', :two)
  end
  
  it "should call definers" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one, Definers.writer, Definers.reader, Definers.accessor
    end
    klass.should has_no_methods
  end
  
  it "should send property name to definer" do
    definer = mock
    definer.stub!(:accessor).with(:one)
    klass = Class.new do
      include PlainRecord::Resource
      property :one, definer.method(:accessor)
    end
  end
  
  it "should load data from file" do
    first_file  = File.join(File.dirname(__FILE__), 'data/1/post.m')
    second_file = File.join(File.dirname(__FILE__), 'data/2/post.m')
    
    obj = Post.load_file(first_file)
    obj.should be_a(Post)
    obj.title.should == 'First'
    
    obj = Post.load_file(second_file)
    obj.should be_a(Post)
    obj.title.should be_nil
  end
  
end
