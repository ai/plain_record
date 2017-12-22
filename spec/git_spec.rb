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
    allow(Time).to receive(:now).and_return(@now)
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

end
