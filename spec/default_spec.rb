require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Default do

  it "should set default value for field" do
    klass = Class.new do
      include PlainRecord::Resource
      entry_in 'data/*/post.md'
      field :category, default('uncategorized')
    end
    post = klass.new

    post.category.should == 'uncategorized'
    post.category = 'a'
    post.category.should == 'a'
  end

end
