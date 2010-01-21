class Author
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :name, String, :required => true
  property :born_at, DateTime
  property :died_at, DateTime

  has n, :quotes

  after :save, :set_id
end
