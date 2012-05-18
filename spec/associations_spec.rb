require File.join(File.dirname(__FILE__), 'spec_helper')

describe PlainRecord::Associations do

  before :all do
    class ::Rate
      include PlainRecord::Resource
    end

    class ::RatedPost
      include PlainRecord::Resource
      entry_in 'data/3/post.md'
      field :rate, one(::Rate)
    end

    class ::Comment
      include PlainRecord::Resource

      list_in 'data/*/comments.yml'

      virtual :commented_post_name, in_filepath(1)
      virtual :commented_post,      one(::FilepathPost)

      field :author_name
      field :text
      field :answers, many(::Comment)
    end

    class ::CommentedPost
      include PlainRecord::Resource
      entry_in 'data/*/post.md'
      virtual :name,     in_filepath(1)
      virtual :comments, many(::Comment)
    end
  end

  it "shouldn't create association for text" do
    lambda {
      Class.new do
        include PlainRecord::Resource
        text :one, one(Post)
      end
    }.should raise_error(ArgumentError, /text creator/)

    lambda {
      Class.new do
        include PlainRecord::Resource
        text :many, many(Post)
      end
    }.should raise_error(ArgumentError, /text creator/)
  end

  it "should load one-to-one real association" do
    rate = ::RatedPost.first().rate
    rate.should be_instance_of(::Rate)
    rate.path.should == 'data/3/post.md'
    rate.data.should == { 'subject' => 5, 'text' => 2 }
  end

  it "should save one-to-one real association" do
    file = StringIO.new
    File.should_receive(:open).with(anything(), 'w').and_yield(file)

    ::RatedPost.first().save()

    file.should has_yaml({ 'title' => 'Third',
                           'rate'  => { 'text' => 2, 'subject' => 5 } })
  end

  it "should load one-to-many real association" do
    root = ::Comment.first()
    root.should have(1).answers
    root.answers[0].should be_instance_of(::Comment)
    root.answers[0].path.should == 'data/1/comments.yml'
    root.answers[0].data.should == { 'author_name' => 'john',
                                     'text'        => 'Thanks',
                                     'answers'     => [] }
  end

  it "should save one-to-many real association" do
    file = StringIO.new
    File.should_receive(:open).with(anything(), 'w').and_yield(file)

    ::Comment.first().save()

    file.should has_yaml([
      {
        'author_name' => 'super1997',
        'text'        => 'Cool!',
        'answers'     => [{ 'author_name' => 'john', 'text' => 'Thanks' }]
      }
    ])
  end

  it "should find map for virtual association" do
    PlainRecord::Associations.map(
        ::Comment, ::CommentedPost, 'commented_post_').should == { 
            :commented_post_name => :name }
  end

  it "should load one-to-one virtual association" do
    post = ::FilepathPost.first(:name => '1')
    comment = ::Comment.first(:author_name => 'super1997')
    comment.commented_post.should == post
  end

  it "should change one-to-one virtual association" do
    post = ::FilepathPost.first(:name => '2')
    comment = ::Comment.first(:author_name => 'super1997')
    comment.commented_post = post

    post.name.should == '1'
    comment.commented_post.should == post
  end

  it "should load one-to-many virtual association" do
    post = ::CommentedPost.first(:name => '1')
    post.should have(1).comments
    post.comments.first.should == ::Comment.first(:author_name => 'super1997')
  end

  it "should add new item to one-to-many virtual association" do
    post = ::CommentedPost.first(:name => '1')
    comment = ::Comment.new
    post.comments << comment

    post.should have(2).comments
    post.comments[1].should == comment
    comment.commented_post_name.should == post.name
  end

  it "should create new one-to-many association" do
    post = ::CommentedPost.new(:name => 'new')
    comment = ::Comment.new
    post.comments = [comment]

    post.should have(1).comments
    post.comments.first.should == comment
    comment.commented_post_name.should == post.name
  end

end
