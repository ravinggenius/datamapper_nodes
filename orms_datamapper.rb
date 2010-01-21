require 'rubygems'
require 'pp'
require 'datamapper'
require 'dm-is-list'
require 'dm-is-nested_set'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-types'

class App
  def self.root
    Dir.pwd
  end
end

config_file = File.new App.root + '/database.yml'

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

class Collection
  include DataMapper::Resource
  include NodeExtension

  property :id, Serial
  property :discriminator, Discriminator, :required => true
  property :node_ids, CommaSeparatedList, :accessor => :protected

  # validate proper sub-types

  before :save do
    @nodes ||= []
    self.node_ids = @nodes.map do |n|
      n = n.node if n.respond_to? :node
      n.id
    end
  end

  after :save, :set_id

  def nodes
    self.node_ids ||= []
    @nodes ||= self.node_ids.map { |node_id| Node.get node_id.to_i }
  end
end

Dir.foreach File.expand_path(App.root + '/lib/nodes') do |file|
  package_model = App.root + "/lib/nodes/#{file}/#{file}.rb"
  next unless File.exist? package_model
  require package_model
end

DataMapper.auto_migrate!

u = User.new :name => 'Thomas Ingram', :email => 'thomas@ravinggenius.com'
u.save

n = List.new
n.items << 'Make this work'
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
Node.all.each do |node|
  puts "Node#id => #{node.id}, #{node.extension.class.name}#id => #{node.extension.id}"
end

puts

puts 'Listing all collections, associated node and any child nodes'
Collection.all.each do |collection|
  #puts "Node#id => #{node.id}, #{node.extension.class.name}#id => #{node.extension.id}"
  #puts node.extension.nodes.inspect if node.extension.respond_to? :nodes
  puts collection.inspect
  puts collection.node.inspect
  puts collection.nodes.inspect
  puts
end
