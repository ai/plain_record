require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Model do
  
  it "should define property" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one
    end
    
    klass.properties.should == [:one]
    object = klass.new(nil, {'one' => 1}, [])
    object.one.should == 1
    object.one = 2
    object.one.should == 2
  end
  
  it "should define text" do
    klass = Class.new do
      include PlainRecord::Resource
      text :content
    end
    
    klass.texts.should == [:content]
    object = klass.new(nil, {}, ['text'])
    object.content.should == 'text'
    object.content = 'another'
    object.content.should == 'another'
  end
  
  it "should call definer" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one, Definers.accessor
      property :two, Definers.reader
      text :three, Definers.writer
      text :four, Definers.none
    end
    klass.should has_methods(:one, :'one=', :'three=', :two)
  end
  
  it "should use accessors from definers" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one, Definers.writer, Definers.reader, Definers.accessor
      text :two, Definers.reader
    end
    klass.should has_methods(:two)
  end
  
  it "should send property name to definer" do
    definer = mock
    definer.stub!(:accessor).with(:one)
    klass = Class.new do
      include PlainRecord::Resource
      property :one, definer.method(:accessor)
    end
  end
  
  it "should find all model files by glob pattern" do
    klass = Class.new do
      include PlainRecord::Resource
      entry_in 'data/*/post.m'
    end
    klass.files.sort.should == [FIRST, SECOND, THIRD]
  end
  
  it "should load YAML data from file" do
    obj = Post.load_file(FIRST)
    obj.should be_a(Post)
    obj.title.should == 'First'
    
    obj = Post.load_file(SECOND)
    obj.should be_a(Post)
    obj.title.should be_nil
  end
  
  it "should load text data from entry file" do
    obj = Post.load_file(FIRST)
    obj.summary.should == 'first --- content'
    obj.content.rstrip.should == "big\n---\ncontent"
    
    obj = Post.load_file(SECOND)
    obj.summary.rstrip.should == " only one"
    obj.content.should be_nil
  end
  
  it "should load all entries" do
    Post.all.should == [SECOND_POST, THIRD_POST, FIRST_POST]
  end
  
  it "should return entries by string matcher" do
    Post.all(:title => 'First').should == [FIRST_POST]
  end
  
  it "should return entries by regexp matcher" do
    Post.all(:title => /First/, :title => /Second/).should be_empty
  end
  
  it "should return entries by search proc" do
    Post.all { |i| not i.title.nil? }.should == [THIRD_POST, FIRST_POST]
  end
  
  it "should return first entry" do
    Post.first.should be_a(Post)
  end
  
  it "should return entry by string matcher" do
    Post.first(:title => 'Third').should == THIRD_POST
  end
  
  it "should return entry by regexp matcher" do
    Post.first(:title => /First|Third/).should == THIRD_POST
  end
  
  it "should return entry by search proc" do
    Post.first { |i| false }.should be_nil
  end
  
end
