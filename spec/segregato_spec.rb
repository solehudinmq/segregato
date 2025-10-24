# frozen_string_literal: true

RSpec.describe Segregato do
  before(:all) do
    puts "TOTAL DATA : #{PostQuery.count}"
    
    @master_db = 'db/coba_cqrs_master.sqlite3'
    @replica1_db = 'db/coba_cqrs_replica1.sqlite3'
    @replica2_db = 'db/coba_cqrs_replica2.sqlite3'
  end

  after(:all) do
    # delete all databases
    db_location = "#{Dir.pwd}/db"
    FileUtils.rm_r(db_location) if File.exist?(db_location)
  end

  it "return success when writing data to the master database" do
    PostCommand.create!(
      title: 'Post 1 Title', 
      content: 'Post 1 Content',
      view: 1
    )

    copy_sqlite_data(@master_db, @replica1_db)
    copy_sqlite_data(@master_db, @replica2_db)

    post = PostQuery.find_by(title: 'Post 1 Title')
    
    expect(post.title).to eq 'Post 1 Title'
    expect(post.content).to eq 'Post 1 Content'
  end

  it "return success when read data from the replica database" do
    posts = PostQuery.all
    
    expect(posts.size).to be 1
    expect(posts[0].title).to eq 'Post 1 Title'
    expect(posts[0].content).to eq 'Post 1 Content'
  end

  it "return failed when write data tried using read method" do
    begin
      PostCommand.all
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: all"
    end

    begin
      PostCommand.find(title: 'Post 1 Title')
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: find"
    end

    begin
      PostCommand.find_by(title: 'Post 1 Title')
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: find_by"
    end

    begin
      PostCommand.where(title: 'Post 1 Title')
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: where"
    end

    begin
      PostCommand.first
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: first"
    end

    begin
      PostCommand.last
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: last"
    end

    begin
      PostCommand.limit(10)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: limit"
    end

    begin
      PostCommand.pluck(:id)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: pluck"
    end

    begin
      PostCommand.exists?
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: exists?"
    end

    begin
      PostCommand.count
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: count"
    end

    begin
      PostCommand.sum(:view)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: sum"
    end

    begin
      PostCommand.average(:view)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: average"
    end

    begin
      PostCommand.minimum(:view)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: minimum"
    end

    begin
      PostCommand.maximum(:view)
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: maximum"
    end

    begin
      PostCommand.reload
    rescue => e
      expect(e.message).to eq "The Write Model is not allowed to perform the Read operation: reload"
    end
  end

  it "return failed when read data tried using write method" do
    begin
      PostQuery.new(title: 'Post 2 Title', content: 'Post 2 Content').save
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: save"
    end

    begin
      PostQuery.new(title: 'Post 2 Title', content: 'Post 2 Content').save!
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: save!"
    end

    begin
      post = PostQuery.first
      post.update(title: 'Post 2 Title', content: 'Post 2 Content')
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: update"
    end

    begin
      post = PostQuery.first
      post.update!(title: 'Post 2 Title', content: 'Post 2 Content')
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: update!"
    end

    begin
      post = PostQuery.first
      post.destroy
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: destroy"
    end

    begin
      post = PostQuery.first
      post.destroy!
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: destroy!"
    end

    begin
      post = PostQuery.first
      post.delete
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: delete"
    end

    begin
      post = PostQuery.first
      post.delete_all
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: delete_all"
    end

    begin
      posts = PostQuery.all
      posts.update_all(title: 'Post 2 Title', content: 'Post 2 Content')
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: update_all"
    end

    begin
      PostQuery.create(title: 'Post 2 Title', content: 'Post 2 Content')
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: create"
    end

    begin
      PostQuery.create!(title: 'Post 2 Title', content: 'Post 2 Content')
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: create!"
    end

    begin
      PostQuery.insert_all([{title: 'Post 2 Title', content: 'Post 2 Content'}])
    rescue => e
      expect(e.message).to eq "The Read Model is not allowed to perform Write operations: insert_all"
    end
  end
end
