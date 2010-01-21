class Image
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :thumb, Blob
  property :data, Blob, :required => true

  after :save, :set_id
end
