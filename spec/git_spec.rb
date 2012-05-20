require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Extra::Git do

  before :all do
    class TimedPost
      include PlainRecord::Resource
      include PlainRecord::Extra::Git

      entry_in 'data/*/post.md'

      virtual :name,    in_filepath(1)
      field   :created, git_created_time
      field   :updated, git_modified_time
    end
  end

  before do
    @post = TimedPost.first(:name => '2')

    @now = Time.at(256)
    Time.stub!(:now).and_return(@now)
  end

  it "should take file create time from git" do
    @post.created.utc.should == Time.parse('2012-05-17 22:23:47 UTC')
  end

  it "should take file updated time from git" do
    @post.updated.utc.should == Time.parse('2012-05-18 07:41:52 UTC')
  end

  it "should overrided git time" do
    post = TimedPost.new

    post.created = Time.at(0)
    post.created.should == Time.at(0)

    post.updated = Time.at(1)
    post.updated.should == Time.at(1)
  end

  it "should return now for new model" do
    post = TimedPost.new
    post.created.should == @now
    post.updated.should == @now
  end

  it "shoult return now if file has uncommitted changes" do
    @post.stub!(:git_uncommitted?).and_return(true)
    @post.created.utc.should == Time.parse('2012-05-17 22:23:47 UTC')
    @post.updated.should == @now
  end

end
