include Segregato

class PostCommand < StrictWriteBase
  self.table_name = 'posts'
  # Relasi/Validasi Tulis
  validates :title, presence: true, length: { minimum: 1 }
end