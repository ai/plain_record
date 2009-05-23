require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Resource do
  
  it "should compare two object" do
    first = Post.load_file(FIRST)
    another_first = Post.load_file(FIRST)
    second = Post.load_file(SECOND)
    
    first.should == another_first
    first.should_not == second
  end
  
  it "should remeber it file" do
    Post.load_file(FIRST).file.should == FIRST
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
  
  it "should delete list entry" do
    file = StringIO.new
    File.should_receive(:open).with(INTERN, 'w').and_yield(file)
    
    Author.first(:login => 'john').destroy
    
    Author.first(:login => 'john').should be_nil
    file.rewind
    file.read.should == "- login: ivan\n" +
                        "  name: Ivan Ivanov\n"
    
    Author.should_receive(:delete_file).with(INTERN)
    Author.first(:login => 'ivan').destroy
  end
  
end
