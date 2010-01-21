class Link
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :resource, URI, :required => true

  after :save, :set_id
end
