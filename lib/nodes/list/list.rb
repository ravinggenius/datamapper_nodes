class List
  include DataMapper::Resource
  include NodeExtension

  GLUE = "\n"

  property :id, Serial
  property :data, Text, :required => true, :lazy => false, :accessor => :protected

  before :save do
    @items ||= []
    data = @items.join GLUE
  end

  after :save, :set_id

  def items
    data ||= ''
    @items ||= data.split GLUE
  end
end
