require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Callbacks do
  
  it "should use methods without callbacks" do
    klass = Class.new {
      extend Fullname
    }.fullname('John', 'Smith').should == 'John Smith'
  end
  
  it "should use before callbacks by priority" do
    checker = mock()
    checker.should_receive(:check_first).with('John', 'Smith').once.ordered
    checker.should_receive(:check_last).with('John', 'Smith').once.ordered
    
    klass = Class.new {
      extend Fullname
      
      before :fullname, 2, &checker.method(:check_last)
      before :fullname, 1, &checker.method(:check_first)
    }.fullname('John', 'Smith').should == 'John Smith'
  end
  
  it "should use after callbacks by priority" do
    adder = Class.new do
      def self.add_first(full, first, last); full + ' ' + first.downcase end
      def self.add_last(full, first, last); full + ' ' + last.downcase end
    end
    
    klass = Class.new {
      extend Fullname
      
      after :fullname, 2, &adder.method(:add_last)
      after :fullname, 1, &adder.method(:add_first)
    }.fullname('John', 'Smith').should == 'John Smith john smith'
  end
  
end
