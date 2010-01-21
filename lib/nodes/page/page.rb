class Page < Collection
  property :slug, String

  before :save do
    #unless slug
      # set slug from node.title
    #end
  end
end
