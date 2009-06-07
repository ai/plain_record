require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Resource do
  
  after :each do
    Post.loaded = {}
    Author.loaded = {}
  end
  
  it "should compare two object" do
    first = Post.load_file(FIRST)
    another_first = Post.load_file(FIRST)
    second = Post.load_file(SECOND)
    
    first.should == another_first
    first.should_not == second
  end
  
  it "should remeber it file" do
    Post.load_file(FIRST).file.should == FIRST
    Post.load_file(FIRST).path.should == 'data/1/post.m'
  end
  
  it "should save entry" do
    file = StringIO.new
    File.should_receive(:open).with(FIRST, 'w').and_yield(file)
    
    first = Post.first(:title => 'First')
    first.save
    
    file.rewind
    file.read.should == "title: First\n" +
                        "---\n" +
                        "first --- content\n" +
                        "---\n" +
                        "big\n" +
                        "---\n" +
                        "content\n"
  end
  
  it "should save list entry" do
    file = StringIO.new
    Author.all
    File.should_receive(:open).with(INTERN, 'w').and_yield(file)
    
    john = Author.first(:login => 'john')
    john.save
    
    file.rewind
    file.read.should == "- login: john\n" +
                        "  name: John Smith\n" +
                        "- login: ivan\n" +
                        "  name: Ivan Ivanov\n"
  end
  
  it "should delete entry" do
    Post.should_receive(:delete_file).with(FIRST)
    Post.first(:title => 'First').destroy
  end
  
  it "should save entry without file if model use only one file" do
    class Model
      include PlainRecord::Resource
      list_in 'file.yml'
    end
    
    path = File.join(PlainRecord.root, 'file.yml')
    File.should_receive(:open).with(path, 'w').and_yield(StringIO.new)
    Model.new.save
  end
  
  it "should delete list entry" do
    file = StringIO.new
    Author.all
    File.should_receive(:open).with(INTERN, 'w').and_yield(file)
    
    Author.first(:login => 'john').destroy
    
    Author.first(:login => 'john').should be_nil
    file.rewind
    file.read.should == "- login: ivan\n" +
                        "  name: Ivan Ivanov\n"
    
    Author.should_receive(:delete_file).with(INTERN)
    Author.first(:login => 'ivan').destroy
  end
  
  it "should call callbacks" do
    Model = Post.dup
    callbacks = mock()
    callbacks.should_receive(:path).with(Model.path, {:title => 'First'}).
                                    and_return('data/1/post.m')
    callbacks.should_receive(:load).with(an_instance_of(Model))
    callbacks.should_receive(:save).with(an_instance_of(Model)).and_raise
    callbacks.should_receive(:destroy).with(an_instance_of(Model)).and_raise
    
    Model.after  :path,    &callbacks.method(:path)
    Model.before :load,    &callbacks.method(:load)
    Model.before :save,    &callbacks.method(:save)
    Model.before :destroy, &callbacks.method(:destroy)
    
    first = Model.first({:title => 'First'})
    lambda { first.save }.should raise_error
    lambda { first.destroy }.should raise_error
  end
  
end
