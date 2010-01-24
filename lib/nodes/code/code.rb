class Code
  include DataMapper::Resource
  include NodeExtension

  GLUE = "\n"

  property :id, Serial
  property :data, Text, :required => true, :lazy => false

  before :save do
    @lines ||= []
    data = @lines.join GLUE
  end

  after :save, :set_id

  def lines
    data.split GLUE
  end
end
