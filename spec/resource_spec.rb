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
    first.title = 'First 1'
    first.save
    
    file.rewind
    file.read.should == "title: First 1\n" +
                        "---\n" +
                        "first --- content\n" +
                        "---\n" +
                        "big\n" +
                        "---\n" +
                        "content\n"
  end
  
  it "should save in_list entry" do
    file = StringIO.new
    File.should_receive(:open).with(INTERN, 'w').and_yield(file)
    
    john = Author.first(:login => 'john')
    john.name = 'New name'
    john.save
    
    file.rewind
    file.read.should == "- login: john\n" +
                        "  name: New name\n" +
                        "- login: ivan\n" +
                        "  name: Ivan Ivanov\n"
  end
  
end
