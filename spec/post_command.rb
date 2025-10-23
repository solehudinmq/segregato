class PostCommand < StrictWriteBase
  self.table_name = 'posts'

  validates :title, presence: true, length: { minimum: 1 }
end