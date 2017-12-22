require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Extra::I18n do

  before :all do
    class I18nPost
      include PlainRecord::Resource
      include PlainRecord::Extra::I18n
      field :one, i18n
    end

    class PlainI18nPost < I18nPost
      attr_accessor :locale
    end
  end

  it "should raise error on i18n filter on text" do
    lambda {
      klass = Class.new do
        include PlainRecord::Resource
        include PlainRecord::Extra::I18n
        text :one, i18n
      end
    }.should raise_error(ArgumentError, /text/)
  end

  it "should save translations with locale" do
    post = PlainI18nPost.new

    post.locale = 'en'
    post.one = 1
    post.data['one'].should == { 'en' => 1 }

    post.locale = 'ru'
    post.one = 2
    post.data['one'].should == { 'en' => 1, 'ru' => 2 }
  end

  it "should return untraslated field" do
    post = PlainI18nPost.new

    post.locale = 'en'
    post.one = 1
    post.untraslated_one.should == { 'en' => 1 }

    post.untraslated_one = { 'ru' => 2 }
    post.data['one'] == { 'ru' => 2 }
  end

  it "should return original field if it is not hash" do
    post = PlainI18nPost.new
    post.one.should be_nil
    post.data['one'] = 1
    post.one.should == 1
  end

  context 'plain' do

    it "should raise error when locale method is not redefined" do
      klass = Class.new do
        include PlainRecord::Resource
        include PlainRecord::Extra::I18n
        field :one, i18n
      end
      post = klass.new
      lambda { post.locale }.should raise_error(/Redefine/)
    end

    it "should translate method" do
      post = PlainI18nPost.new
      post.data['one'] = { 'en' => 1, 'ru' => 2 }

      post.locale = 'en'
      post.one.should == 1

      post.locale = 'ru'
      post.one.should == 2
    end
  end

  context 'i18n' do
    before :all do
      require 'i18n'
      I18n.config.available_locales = [:en, :ru]
    end

    it "should git locale from I18n" do
      post = I18nPost.new
      post.data['one'] = { 'en' => 1, 'ru' => 2 }

      I18n.locale = :en
      post.one == 1

      I18n.locale = :ru
      post.one == 2

      post.one = 3
      post.data['one'].should == { 'en' => 1, 'ru' => 3 }
    end
  end

  context 'r18n' do
    before :all do
      require 'r18n-core'
    end

    before do
      @post = I18nPost.new
    end

    it "should get I18n object from R18n" do
      @post.data['one'] = { 'en' => 1, 'ru' => 2 }

      R18n.set('en')
      @post.one == 1

      R18n.set('ru')
      @post.one == 2

      @post.one = 3
      @post.data['one'].should == { 'en' => 1, 'ru' => 3 }
    end

    it "should return translated string" do
      @post.data['one'] = { 'en' => '1' }
      R18n.set('en')

      @post.one.should be_translated
      @post.one.locale.code.should == 'en'
      @post.one.path.should == 'I18nPost#one'
    end

    it "should find translation in user locales" do
      @post.data['one'] = { 'fr' => '1' }

      R18n.set(['ru', 'fr'])
      @post.one.should == '1'
    end

    it "should return untraslated" do
      @post.data['one'] = { 'fr' => '1' }
      R18n.set('ru')

      @post.one.should_not be_translated
      @post.one.translated_path.should   == 'I18nPost#'
      @post.one.untranslated_path.should == 'one'
    end

    it "should translate non-strings" do
      @post.data['one'] = { 'ru' => { :a => 1 } }
      R18n.set('ru')

      @post.one.should == { :a => 1 }
    end

    it "should use filters for custom type" do
      klass = Class.new do
        include PlainRecord::Resource
        include PlainRecord::Extra::I18n
        field :one, i18n('pl')
      end
      post = klass.new
      post.data['one'] = { 'en' => { '1' => '%1 one', 'n' => '%1 ones' } }
      post.one(5).should == '5 ones'
    end
  end

end
