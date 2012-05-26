require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Model do

  after :each do
    Post.loaded   = { }
    Author.loaded = { }
  end

  it "should define virtual field" do
    klass = Class.new do
      include PlainRecord::Resource
      virtual :one, proc { }
    end

    klass.virtuals.should == [:one]
  end

  it "shouldn't define virtual field without accessor from filters" do
    lambda {
      Class.new do
        include PlainRecord::Resource
        virtual :one
      end
    }.should raise_error(ArgumentError, /own accessors/)
  end

  it "should define field" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one
    end

    klass.fields.should == [:one]
    klass.accessors_modules[:main].should has_methods(:one, :one=)

    object = klass.new(nil, { 'one' => 1 })
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
    klass.accessors_modules[:main].should has_methods(:content, :content=)

    object = klass.new(nil, { }, ['text'])
    object.content.should == 'text'
    object.content = 'another'
    object.content.should == 'another'
  end

  it "should send field name and type type to filter" do
    klass   = Class.new
    filter = mock
    filter.stub!(:virtual).with(klass, :one, :virtual)
    filter.stub!(:field).with(klass, :two,  :field)
    filter.stub!(:text).with(klass, :three, :text)
    klass.class_eval do
      include PlainRecord::Resource
      virtual :one,   filter.method(:virtual)
      field   :two,   filter.method(:field)
      text    :three, filter.method(:text)
    end
  end

  it "should override sustem accessors by filter" do
    filter = proc do |model, name, type|
      model.add_accessors <<-EOS, __FILE__, __LINE__
        def #{name}
          super + 1
        end
      EOS
    end
    klass = Class.new do
      include PlainRecord::Resource
      field :one, filter
    end
    a = klass.new
    a.one = 1
    a.one.should == 2
  end

  it "should find all enrty files by glob pattern" do
    klass = Class.new do
      include PlainRecord::Resource
      entry_in 'data/*/post.md'
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
    Author.all.map { |i| i.login }.should =~ [nil, 'super1997', 'john', 'ivan']
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
    Author.first { |i| not i.login.nil? and i.type == 'extern' }.
      name.should == 'SuperHacker'
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

  it "should move entry from one file to another" do
    first = Post.first(:title => 'First')
    Post.should_receive(:delete_file).with(FIRST)
    Post.should_receive(:save_file).with(PlainRecord.root('file'))
    first.file = 'file'
    first.save
  end

  it "should move list entry from one file to another" do
    Author.should_receive(:save_file).with(INTERN).once
    Author.should_receive(:save_file).with(PlainRecord.root('file')).twice
    Author.should_receive(:delete_file).with(INTERN).once

    authors = Author.all(:login => /john|ivan/)
    authors.each do |author|
      author.file = 'file'
      author.save
    end
  end

  it "should add modules for accessors" do
    klass = Class.new do
      include PlainRecord::Resource
    end

    klass.accessors_modules.should be_empty

    main = klass.add_accessors(:main)
    klass.add_accessors(:main).should == main
    klass.accessors_modules.should have(1).keys

    mod = klass.add_accessors
    mod.should_not == main
    klass.add_accessors.should_not == mod
    klass.accessors_modules.should have(1).keys
  end

  it "should define accessors" do
    klass = Class.new do
      include PlainRecord::Resource
    end
    klass.add_accessors :one, "def one; 1; end"
    klass.add_accessors       "def two; 2; end"
    klass.add_accessors <<-EOS, __FILE__, __LINE__
       def three; 3; end
    EOS

    klass.should has_methods(:one, :two, :three)
  end

  it "should allow to define filters as Hash" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, :default => 1
    end
    a = klass.new
    a.one.should == 1
  end

end
