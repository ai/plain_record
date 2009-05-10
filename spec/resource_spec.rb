require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Resource do
  
  it "should define property" do
    klass = Class.new do
      include PlainRecord::Resource
      
      property :one
    end
    
    object = klass.new({:one => 1})
    object.one.should == 1
    object.one = 2
    object.one.should == 2
  end
  
end
