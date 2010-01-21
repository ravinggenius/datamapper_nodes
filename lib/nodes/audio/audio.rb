class Audio
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Blob, :required => true

  after :save, :set_id
end
