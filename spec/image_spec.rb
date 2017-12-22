require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Extra::Image do

  before do
    PlainRecord::Extra::Image.dir = 'images/data/'
    PlainRecord::Extra::Image.url = 'data/'

    @klass = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image

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
    PlainRecord::Extra::Image.dir = nil
    PlainRecord::Extra::Image.url = nil

    lambda {
      @klass.get_image_file(@entry, :logo, :small)
    }.should raise_error(ArgumentError, /Image.dir/)

    lambda {
      PlainRecord::Extra::Image.convert_images!
    }.should raise_error(ArgumentError, /Image.dir/)

    lambda {
      @klass.get_image_url(@entry, :logo, :small)
    }.should raise_error(ArgumentError, /Image.url/)
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
    allow(File).to receive(:exists?).and_return(true)
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
    allow(File).to receive(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/logo.png')).and_return(false)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/photo.png')).and_return(true)

    allow(FileUtils).to receive(:mkpath)
    FileUtils.should_receive(:mkpath).with('images/data')
    allow(FileUtils).to receive(:cp)
    FileUtils.should_receive(:cp).
      with(PlainRecord.root('a/photo.png'), 'images/data/photo..png')

    @entry.convert_images!
  end

  it "should resize image", :unless => is_rbx do
    allow(File).to receive(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/logo.png')).and_return(true)

    allow(FileUtils).to receive(:mkpath)
    FileUtils.should_receive(:mkpath).with('images/data')

    thumb = double('thumb')
    allow(thumb).to receive(:write)
    thumb.should_receive(:write).with('images/data/logo.small.png')

    original = double('original')
    allow(original).to receive(:resize)
    original.should_receive(:resize).with(16, 16).and_return(thumb)

    require 'RMagick'
    allow(Magick::Image).to receive(:read)
    Magick::Image.should_receive(:read).
      with(PlainRecord.root('a/logo.png')).and_return([original])

    @entry.convert_images!
  end

  it "should remember all models, which use extention" do
    PlainRecord::Extra::Image.included_in = []

    one = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image
    end
    two = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image
    end

    PlainRecord::Extra::Image.included_in.should == [one, two]
  end

  it "should delete all old image" do
    PlainRecord::Extra::Image.included_in = [@klass]

    def @klass.entry
      @entry ||= self.new
    end
    def @klass.all
      [entry]
    end

    allow(Dir).to receive(:glob).and_yield('images/data/a.png')
    Dir.should_receive(:glob).with('images/data/**/*')

    allow(File).to receive(:exists?).and_return(true)
    File.should_receive(:exists?).with('images/data/a.png')

    allow(FileUtils).to receive(:rm_r)
    FileUtils.should_receive(:rm_r).with('images/data/a.png')

    @klass.entry.stub(:convert_images!)
    @klass.entry.should_receive(:convert_images!)

    PlainRecord::Extra::Image.convert_images!
  end

  it "should return right error on wrong size" do
    lambda {
      @entry.logo(:no)
    }.should raise_error(ArgumentError, "Field `logo` doesn't have `no` size")
  end

end
