require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord do

  original_root = PlainRecord.root
  after { PlainRecord.root = original_root }

  it "should save root" do
    PlainRecord.root = 'a/'
    PlainRecord.root.should == 'a/'
  end

  it "should add last slash to root" do
    PlainRecord.root = 'a'
    PlainRecord.root.should == 'a/'
  end

  it "should set pathname to root" do
    PlainRecord.root = Pathname('a')
    PlainRecord.root.should == 'a/'
  end

  it "should join path to root" do
    PlainRecord.root = 'a'
    PlainRecord.root('b').should == 'a/b'
  end

end
