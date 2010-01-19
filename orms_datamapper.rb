require 'rubygems'
require 'pp'
require 'datamapper'
require 'dm-is-list'
require 'dm-is-nested_set'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-types'

class Blob < DataMapper::Type
  #primitive Text
  primitive String

  def self.dump value, property
  end

  def self.load value, property
  end

  #def self.typecast value, property
  #end
end

config_file = File.new File.expand_path(File.dirname(__FILE__) + '/database.yml')

DataMapper.setup :default, YAML.load(config_file)['datamapper']

class Login
  include DataMapper::Resource

  property :id, Serial
  property :username, String, :required => true
  property :hashword, String, :required => true, :accessor => :private
  property :salt, String, :required => true, :accessor => :private

  belongs_to :user
end

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :email, String, :required => true

  has n, :groups, :through => Resource
  has n, :logins
  has n, :nodes
end

class Group
  include DataMapper::Resource

  property :id, Serial
  property :access_code, Integer, :required => true, :unique => true
  property :code, String, :required => true
  property :name, String, :required => true

  has n, :users, :through => Resource

  before :save do
    # validate access code
  end
end

class Vocabulary
  include DataMapper::Resource

  property :id, Serial
  property :code, String, :required => true
  property :name, String, :required => true
  # ...

  has n, :terms
  has n, :nodes, :through => Resource
end

class Term
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true

  belongs_to :vocabulary
  has n, :nodes, :through => Resource
end

class Node
  include DataMapper::Resource

  property :id, Serial
  property :title, String, :required => true
  property :type_id, Integer, :required => true
  property :type_name, String, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :user
  has n, :vocabularies, :through => Resource
  has n, :terms, :through => Resource

  is :list
  #is :tree

  def extension
    @extension ||= Kernel.const_get(type_name).get(type_id)
  end
end

module NodeExtension
  def node
    @node ||= Node.first node_params
    @node ||= Node.new node_params
  end

  def method_missing missing_method, *args
    if node.respond_to? missing_method
      node.send missing_method, *args
    else
      super
    end
  end

  private

  def node_params
    { :type_id => self.id, :type_name => self.class.name }
  end

  def set_id
    node.type_id = self.id
    node.save
  end
end

class UserDetail
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial

  after :save, :set_id
end

class Text
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Text, :required => true, :lazy => false

  after :save, :set_id
end

class Code
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Text, :required => true, :lazy => false

  after :save, :set_id
end

class Table
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :caption, String, :required => true
  property :data, Csv, :required => true, :lazy => false
  property :has_header_row, Boolean, :required => true, :default => true

  after :save, :set_id
end

class Link
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :resource, URI, :required => true

  after :save, :set_id
end

class Event
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :starting_at, DateTime, :required => true
  property :ending_at, DateTime, :required => true
  property :description, Text

  after :save, :set_id
end

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
    @items ||= data.split GLUE
  end
end

class Quote
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Text, :required => true, :lazy => false

  belongs_to :author

  after :save, :set_id
end

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

class Image
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :thumb, Blob
  property :data, Blob, :required => true

  after :save, :set_id
end

class Audio
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Blob, :required => true

  after :save, :set_id
end

class Video
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :data, Blob, :required => true

  after :save, :set_id
end

class Location
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  # ...

  after :save, :set_id
end

class Collection
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :discriminator, Discriminator, :required => true
  property :node_ids, CommaSeparatedList, :accessor => :protected

  before :save do
    # ensure proper sub-types
  end

  before :save do
    @nodes ||= []
    node_ids = @nodes.map do |n|
      n = n.node if n.respond_to? :node
      n.id
    end
  end

  after :save, :set_id

  def nodes
    node_ids ||= []
    @nodes ||= node_ids.map { |node_id| Node.get node_id.to_i }
  end
end

class Post < Collection; end
class Calendar < Collection; end
class Comment < Collection; end
class Map < Collection; end
class Gallery < Collection; end
class Album < Collection; end

class Page < Collection
  property :slug, String

  before :save do
    #unless slug
      # set slug from node.title
    #end
  end
end

DataMapper.auto_migrate!

u = User.new :name => 'Thomas Ingram', :email => 'thomas@ravinggenius.com'
u.save

n = List.new :data => 'Make this work'
n.title = 'Check out this mighty List!'
n.user = u
n.save

n = Table.new :caption => '(It\'s not really that impressive)', :data => '"One","Two"'
n.title = 'Impressive dataset'
n.user = u
n.save

n = Text.new :data => 'Welcome to Raving Genius\' ScratchPad!'
n.title = 'Welcome'
n.user = u
n.save

n = Page.new :slug => 'about'
n.title = 'About Us'
n.user = u
n.nodes << Text.first << List.first
n.save

n = Comment.new
n.title = 'My Awesome Comment'
n.user = u
n.nodes << Text.first << Table.first
n.save

puts 'Listing all nodes and associated extensions'
puts

Node.all.each do |node|
  puts node.inspect
  puts node.extension.inspect
  puts node.extension.nodes if node.extension.respond_to? :nodes
  puts
end
