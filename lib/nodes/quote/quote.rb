class Quote
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Text, :required => true, :lazy => false

  belongs_to :author

  after :save, :set_id
end
