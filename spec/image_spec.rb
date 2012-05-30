require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Extra::Image do

  before do
    @klass = Class.new do
      include PlainRecord::Resource
      include PlainRecord::Extra::Image

      image_from { |entry, field|       "#{entry.name}/#{field}.png" }
      image_url  { |entry, field, size| "#{field}.#{size}.png" }

      field   :name
      virtual :logo,  image(:small => '16x16')
      virtual :photo, image
    end
  end

  after do
    PlainRecord::Extra::Image.convert_on_each_request = false
  end

  it "should calculate paths" do
    @klass.class_exec do
      image_to   { |entry, field, size| "#{entry.name}/#{field}.#{size}.png" }
    end
    one = @klass.new
    one.name = 'a'

    @klass.get_image_from(one, :logo).should == PlainRecord.root('a/logo.png')
    @klass.get_image_to(one,   :logo, :small).should  == 'a/logo.small.png'
    @klass.get_image_url(one,  :logo, :small).should  == 'logo.small.png'
  end

  it "should throw error if there is no image_to" do
    lambda {
      @klass.get_image_to(@klass.new, :logo, :small)
    }.should raise_error(ArgumentError, /image_to/)
  end

  it "should convert url to file by image_url_to_path" do
    def @klass.image_url_to_path(url)
      'p/' + url
    end

    @klass.get_image_to(@klass.new, :logo, :small).should == 'p/logo.small.png'
  end

  it "should return image data" do
    def @klass.image_url_to_path(url)
      'p/' + url
    end
    one = @klass.new
    one.name = 'a'

    one.logo.should_not be_exists
    File.stub!(:exists?).and_return(true)
    one.logo.should be_exists

    one.logo.original.should == PlainRecord.root('a/logo.png')
    one.logo.file.should be_nil
    one.logo.url.should  be_nil
    one.logo(:small).url.should       == 'logo.small.png'
    one.logo(:small).file.should      == 'p/logo.small.png'
    one.logo(:small).size.should      == '16x16'
    one.logo(:small).width.should     ==  16
    one.logo(:small).height.should    ==  16
    one.logo(:small).size_name.should == :small
    one.photo.url.should              == 'photo..png'
  end

  it "should copy image without size" do
    def @klass.image_url_to_path(url)
      'p/' + url
    end
    one = @klass.new
    one.name = 'a'

    File.stub!(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/photo.png')).and_return(true)

    FileUtils.stub!(:cp)
    FileUtils.should_receive(:cp).
      with(PlainRecord.root('a/photo.png'), 'p/photo..png')

    one.convert_images!
  end

  it "should resize image" do
    def @klass.image_url_to_path(url)
      'p/' + url
    end
    one = @klass.new
    one.name = 'a'

    File.stub!(:exists?)
    File.should_receive(:exists?).
      with(PlainRecord.root('a/logo.png')).and_return(true)

    thumb = double('thumb')
    thumb.stub!(:write)
    thumb.should_receive(:write).with('p/logo.small.png')

    original = double('original')
    original.stub!(:resize)
    original.should_receive(:resize).with(16, 16).and_return(thumb)

    Magick::Image.stub!(:read)
    Magick::Image.should_receive(:read).
      with(PlainRecord.root('a/logo.png')).and_return([original])

    one.convert_images!
  end

  it "should convert images on every call in development" do
    def @klass.image_url_to_path(url)
      'p/' + url
    end
    one = @klass.new

    PlainRecord::Extra::Image.convert_on_each_request = true
    one.stub(:convert_images!)

    one.should_receive(:convert_images!)
    one.photo
  end

end
