require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::File do

  it "should calculate file path" do
    locale = 'en'
    klass = Class.new do
      include PlainRecord::Resource
      field   :name
      virtual :a, file('a')
      virtual :b, file { |i| "#{i.name}.#{locale}" }
    end
    one = klass.new

    one.name = '1'
    one.field_filepath(:a).should == PlainRecord.root('a')
    one.field_filepath(:b).should == PlainRecord.root('1.en')
  end

  it "should read field from file" do
    File.stub(:read)

    type = '1'
    klass = Class.new do
      include PlainRecord::Resource
      virtual :a, file { type }
    end

    one = klass.new
    File.should_receive(:read).with(PlainRecord.root('1')).and_return('A')
    one.a.should == 'A'

    type = '2'
    File.should_receive(:read).with(PlainRecord.root('2')).and_return('B')
    one.a.should == 'B'
  end

  it "should cache new value" do
    type = '1'
    klass = Class.new do
      include PlainRecord::Resource
      virtual :a, file { type }
    end

    one = klass.new
    one.a = 1
    one.unsaved_files.should == { PlainRecord.root('1') => 1 }
    one.a.should == 1

    type = '2'
    one.a = 2
    one.unsaved_files.should == { PlainRecord.root('1') => 1,
                                  PlainRecord.root('2') => 2 }
    one.a.should == 2
  end

  it "should save new value to file" do
    file = ''
    File.stub(:open)
    File.should_receive(:open).with(PlainRecord.root('a'), 'w').and_yield(file)
    File.should_receive(:open).with(PlainRecord.root('file'), 'w').and_yield("")

    klass = Class.new do
      include PlainRecord::Resource
      entry_in 'file'
      virtual :a, file('a')
    end

    one = klass.new
    one.a = 'B'
    one.save

    one.unsaved_files.should == { }
    file.should == 'B'
  end

end
