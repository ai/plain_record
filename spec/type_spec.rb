require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Type do

  originParsers     = PlainRecord::Type.parsers
  originStringifies = PlainRecord::Type.stringifies
  after do
    PlainRecord::Type.parsers     = originParsers
    PlainRecord::Type.stringifies = originStringifies
  end

  it "should set field type to string" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(String)
    end

    a = klass.new
    a.one.should be_nil

    a.data['one'] = 1
    a.one.should == '1'

    a.one = 2
    a.data['one'].should == '2'

    a.one = nil
    a.data['one'].should be_nil
  end

  it "should set field type to integer" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(Integer)
    end

    a = klass.new
    a.one.should be_nil

    a.data['one'] = '1'
    a.one.should == 1

    a.one = '2'
    a.data['one'].should == 2

    a.one = nil
    a.data['one'].should be_nil
  end

  it "should set field type to float" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(Float)
    end

    a = klass.new
    a.one.should be_nil

    a.data['one'] = '1.5'
    a.one.should == 1.5

    a.one = '2.5'
    a.data['one'].should == 2.5

    a.one = nil
    a.data['one'].should be_nil
  end

  it "should set field type to time" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(Time)
    end

    a = klass.new
    a.one.should be_nil

    a.data['one'] = '1970-01-01 00:00:00 UTC'
    a.one.should == Time.at(0).utc

    a.one = Time.at(1).utc
    a.data['one'].should =~ /1970-01-01 00:00:01 (UTC|GMT)/

    a.one = nil
    a.data['one'].should be_nil
  end

  it "should set field type to date" do
    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(Date)
    end

    a = klass.new
    a.one.should be_nil

    a.data['one'] = '1970-01-01'
    a.one.should == Date.parse('1970-01-01')

    a.one = Date.parse('1970-01-02')
    a.data['one'].should == '1970-01-02'

    a.one = nil
    a.data['one'].should be_nil
  end

  it "should allow to set custom type" do
    type = Class.new
    PlainRecord::Type.parsers     = { type => '1' }
    PlainRecord::Type.stringifies = { type => '2' }

    klass = Class.new do
      include PlainRecord::Resource
      field :one, type(type)
    end

    a = klass.new
    a.one.should == 1
    a.one = 5
    a.data['one'].should == 2
  end

end
