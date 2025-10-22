# app.rb
require 'sinatra'
require 'json'
require 'byebug'
require 'segregato'
require 'dotenv/load'
require_relative 'models/post_command'
require_relative 'models/post_query'

before do
  puts "ENV = #{ENV['DB_ENV']}"
  content_type :json
end

# write operations
post '/posts' do
  begin
    data = JSON.parse(request.body.read)
        
    post = PostCommand.create!(
      title: data['title'], 
      content: data['content']
    )
    
    status 201
    { message: "Post berhasil dibuat.", id: post.id }.to_json
  rescue => e
    status 500
    return { error: e.message }.to_json
  end
end

get '/posts' do
  begin
    # Operasi READ akan memicu round-robin koneksi replica
    posts = PostQuery.all.map do |post|
      { 
        id: post.id, 
        title: post.title, 
        content: post.content 
      }
    end

    { count: posts.size, posts: posts }.to_json
  rescue => e
    status 500
    return { error: e.message }.to_json
  end
end

# how to run : 
# note : make sure the gem segregato folder is aligned with your application folder. 
# 1. bundle install
# 2. setup / running database replication
#   - setup
#     ikuti langkah yang ada di file 'db_replication_migration.txt'
#   - running
#     ikuti langkah yang ada di file 'running_db_replication.txt'
# 3. sesuaikan config di 'database.yml'
# 4. bundle exec ruby app.rb
# 5. panggil API : 
#    - Query (read)
#      curl --location 'http://0.0.0.0:4567/posts'
#    - Command (write)
#      curl --location 'http://0.0.0.0:4567/posts' \
#       --header 'Content-Type: application/json' \
#       --data '{
#           "title": "Post 1",
#           "content": "Content post 1"
#       }'