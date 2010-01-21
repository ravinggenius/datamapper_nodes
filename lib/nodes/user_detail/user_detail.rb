class UserDetail
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial

  after :save, :set_id
end
