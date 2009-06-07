require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Filepath do
  
  before :all do
    class ::FilepathPost
      include PlainRecord::Resource
      
      entry_in 'data/**/*/post.m'
      
      property :category, in_filepath(1)
      property :id,       in_filepath(2)
      
      property :title
    end
  end
  
  it "should load filepath property" do
    best = ::FilepathPost.first(:title => 'Best')
    best.category.should == 'best/'
    best.id.should == '4'
  end
  
  it "should load filepath property as nil when ** pattern is empty" do
    ::FilepathPost.first(:title => 'First').category.should be_empty
  end
  
  it "should return more accurate path by filepath properties" do
    ::FilepathPost.path(:id => 2).should == 'data/**/2/post.m'
  end
  
  it "should use filepath properties in search" do
    ::FilepathPost.loaded = {}
    ::FilepathPost.all(:category => 'best/')
    ::FilepathPost.loaded.should have(1).keys
  end
  
  it "should load properties from model constructor" do
    post = ::FilepathPost.new(:id => 5)
    post.id.should == 5
    post.category.should be_nil
  end
  
  it "should get entry path by filepath properties" do
    path = File.join(File.dirname(__FILE__), 'data/5/post.m')
    File.should_receive(:open).with(path, 'w').and_yield(StringIO.new)
    post = ::FilepathPost.new(:id => 5, :category => '').save
  end
  
  it "should raise error, when can't get entry path by filepath properties" do
    post = ::FilepathPost.new
    lambda { post.save }.should raise_error(ArgumentError, /isn't file to save/)
  end
  
end
