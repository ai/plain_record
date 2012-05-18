require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Filepath do

  it "shouldn't create non-virtual filepath field" do
    lambda {
      Class.new do
        include PlainRecord::Resource
        entry_in 'data/*/post.md'
        field :category, in_filepath(1)
      end
    }.should raise_error(ArgumentError, /virtual creator/)
  end

  it "should load filepath field" do
    best = FilepathPost.first(:title => 'Best')
    best.category.should == 'best/'
    best.name.should == '4'
  end

  it "should load filepath field as nil when ** pattern is empty" do
    FilepathPost.first(:title => 'First').category.should be_empty
  end

  it "should return more accurate path by filepath fields" do
    FilepathPost.path(:name => 2).should == 'data/**/2/post.md'
  end

  it "should use filepath fields in search" do
    FilepathPost.loaded = { }
    FilepathPost.all(:category => 'best/')
    FilepathPost.loaded.should have(1).keys
  end

  it "should load fields from model constructor" do
    post = FilepathPost.new(:name => 5)
    post.name.should == 5
    post.category.should be_nil
  end

  it "should get entry path by filepath fields" do
    path = File.join(File.dirname(__FILE__), 'data/5/post.md')
    post = FilepathPost.new(:name => 5, :category => '')
    FilepathPost.should_receive(:move_entry).with(post, nil, path)
    post.save
  end

  it "should raise error, when can't get entry path by filepath fields" do
    post = FilepathPost.new
    lambda { post.save }.should raise_error(ArgumentError, /isn't file to save/)
  end

end
