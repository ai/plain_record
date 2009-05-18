require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Resource do
  
  it "should compare two object" do
    first = Post.load_file(FIRST)
    another_first = Post.load_file(FIRST)
    second = Post.load_file(SECOND)
    
    first.should == another_first
    first.should_not == second
  end
  
end
