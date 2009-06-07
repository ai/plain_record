require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Model do
  
  it "should define property" do
    klass = Class.new do
      include PlainRecord::Resource
      property :one
    end
    
    klass.properties.should == [:one]
    object = klass.new(nil, {'one' => 1})
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
  
  it "should find all enrty files by glob pattern" do
    klass = Class.new do
      include PlainRecord::Resource
      entry_in 'data/*/post.m'
    end
    klass.storage.should == :entry
    klass.files.sort.should == [FIRST, SECOND, THIRD]
  end
  
  it "should find all list files by glob pattern" do
    klass = Class.new do
      include PlainRecord::Resource
      list_in 'data/authors/*.yml'
    end
    klass.storage.should == :list
    klass.files.sort.should == [EXTERN, INTERN]
  end
  
  it "should load YAML data from entry file" do
    obj = Post.load_file(FIRST)
    obj.should be_a(Post)
    obj.title.should == 'First'
    
    obj = Post.load_file(SECOND)
    obj.should be_a(Post)
    obj.title.should be_nil
  end
  
  it "should load text data from entry file" do
    post = Post.load_file(FIRST)
    post.summary.should == 'first --- content'
    post.content.rstrip.should == "big\n---\ncontent"
    
    post = Post.load_file(SECOND)
    post.summary.rstrip.should == " only one"
    post.content.should be_nil
  end
  
  it "should load data from list file" do
    authors = Author.load_file(EXTERN)
    authors.length.should == 2
    
    authors[0].should be_a(Author)
    authors[0].login.should be_nil
    authors[0].name.should == 'Anonymous'
    
    authors[1].should be_a(Author)
    authors[1].login.should == 'super1997'
    authors[1].name.should == 'SuperHacker'
  end
  
  it "shouldn't define text data in model with list storage" do
    lambda {
      klass = Class.new do
        include PlainRecord::Resource
        list_in 'data/authors/*.yml'
        text :content
      end
    }.should raise_error /entry_in/
  end
  
  it "should load all entries" do
    Post.all.should =~ [SECOND_POST, THIRD_POST, FIRST_POST]
  end
  
  it "should return entries by string matcher" do
    Post.all(:title => 'First').should == [FIRST_POST]
  end
  
  it "should return entries by regexp matcher" do
    Post.all(:title => /First/, :title => /Second/).should be_empty
  end
  
  it "should return entries by search proc" do
    Post.all { |i| not i.title.nil? }.should =~ [THIRD_POST, FIRST_POST]
  end
  
  it "should return all list entries" do
    Author.all.map { |i| i.login }.should == [nil, 'super1997', 'john', 'ivan']
  end
  
  it "should return first entry" do
    Post.first.should be_a(Post)
  end
  
  it "should return entry by string matcher" do
    Post.first(:title => 'Third').should == THIRD_POST
  end
  
  it "should return entry by regexp matcher" do
    Post.first(:title => /First/).should == FIRST_POST
  end
  
  it "should return entry by search proc" do
    Post.first { |i| false }.should be_nil
  end
  
  it "should return first list entry" do
    Author.first { |i| not i.login.nil? }.name.should == 'SuperHacker'
  end
  
  it "should delete file, cache and empty dirs" do
    File.should_receive(:delete).with(FIRST)
    
    first_dir = File.dirname(FIRST)
    Dir.should_receive(:entries).with(first_dir).and_return(['.', '..'])
    Dir.should_receive(:rmdir).with(first_dir)
    Dir.should_receive(:entries).with(File.dirname(first_dir)).and_return(
        ['.', '..', '2', '3'])
    
    Post.instance_eval { delete_file(FIRST) }
    Post.loaded.should_not have_key(FIRST)
  end
  
end
