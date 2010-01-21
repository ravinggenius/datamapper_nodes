class Event
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :starting_at, DateTime, :required => true
  property :ending_at, DateTime, :required => true
  property :description, Text

  after :save, :set_id
end
