require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Extra::Image do

  before do
    @klass = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image

      self.converted_images_dir = 'images/data/'
      self.converted_images_url = 'data/'

      image_from { |entry, field|       "#{entry.name}/#{field}.png" }
      image_url  { |entry, field, size| "#{field}.#{size}.png" }

      field   :name
      virtual :logo,  image(:small => '16x16')
      virtual :photo, image
    end

    @entry = @klass.new
    @entry.name = 'a'
  end

  it "should throw error if there is no image_to" do
    klass = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image

      image_from { "a" }
      image_url  { "b" }

      field   :name
      virtual :logo,  image(:small => '16x16')
    end

    lambda {
      klass.get_image_file(klass.new, :logo, :small)
    }.should raise_error(ArgumentError, /converted_images_dir/)

    lambda {
      klass.convert_images!
    }.should raise_error(ArgumentError, /converted_images_dir/)

    lambda {
      klass.get_image_url(klass.new, :logo, :small)
    }.should raise_error(ArgumentError, /converted_images_url/)
  end

  it "should calculate paths" do
    @klass.get_image_from(@entry, :logo).should ==
      PlainRecord.root('a/logo.png')
    @klass.get_image_file(@entry, :logo, :small).should ==
      'images/data/logo.small.png'
    @klass.get_image_url(@entry,  :logo, :small).should ==
      'data/logo.small.png'
  end

  it "should return image data" do
    @entry.logo.should_not be_exists
    File.stub!(:exists?).and_return(true)
    @entry.logo.should be_exists

    @entry.logo.original.should == PlainRecord.root('a/logo.png')
    @entry.logo.file.should be_nil
    @entry.logo.url.should  be_nil
    @entry.logo(:small).url.should       == 'data/logo.small.png'
    @entry.logo(:small).file.should      == 'images/data/logo.small.png'
    @entry.logo(:small).size.should      == '16x16'
    @entry.logo(:small).width.should     ==  16
    @entry.logo(:small).height.should    ==  16
    @entry.logo(:small).size_name.should == :small
    @entry.photo.url.should              == 'data/photo..png'
  end

  it "should copy image without size" do
    File.stub!(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/logo.png')).and_return(false)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/photo.png')).and_return(true)

    FileUtils.stub!(:cp)
    FileUtils.should_receive(:cp).
      with(PlainRecord.root('a/photo.png'), 'images/data/photo..png')

    @entry.convert_images!
  end

  it "should resize image", :unless => defined?(JRUBY_VERSION) do
    File.stub!(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/logo.png')).and_return(true)

    thumb = double('thumb')
    thumb.stub!(:write)
    thumb.should_receive(:write).with('images/data/logo.small.png')

    original = double('original')
    original.stub!(:resize)
    original.should_receive(:resize).with(16, 16).and_return(thumb)

    require 'RMagick'
    Magick::Image.stub!(:read)
    Magick::Image.should_receive(:read).
      with(PlainRecord.root('a/logo.png')).and_return([original])

    @entry.convert_images!
  end

  it "should delete all old image" do
    def @klass.entry
      @entry ||= self.new
    end
    def @klass.all
      [entry]
    end

    Dir.stub!(:glob).and_yield('images/data/a.png')
    Dir.should_receive(:glob).with('images/data/**/*')

    File.stub!(:exists?).and_return(true)
    File.should_receive(:exists?).with('images/data/a.png')

    FileUtils.stub!(:rm_r)
    FileUtils.should_receive(:rm_r).with('images/data/a.png')

    @klass.entry.stub(:convert_images!)
    @klass.entry.should_receive(:convert_images!)

    @klass.convert_images!
  end

  it "should convert images in all models" do
    PlainRecord::Extra::Image.included_in = []

    one = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image
    end
    two = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image
    end

    one.stub(:convert_images!)
    two.stub(:convert_images!)

    one.should_receive(:convert_images!).once
    two.should_receive(:convert_images!).once

    PlainRecord::Extra::Image.convert_images!
  end

end
