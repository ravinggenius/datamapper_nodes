require File.expand_path(Dir.pwd + '/app')
require 'shoulda'

class NodeTests < Test::Unit::TestCase
  context 'Nodes' do
    setup do
      @u = User.new :name => 'Thomas Ingram', :email => 'thomas@ravinggenius.com'
      @u.save

      n = List.new
      n.items << 'Make this work'
      n.title = 'Check out this mighty List!'
      n.user = @u
      n.save

      n = Table.new :caption => '(It\'s not really that impressive)', :data => '"One","Two"'
      n.title = 'Impressive dataset'
      n.user = @u
      n.save

      n = Text.new :data => 'Welcome to Raving Genius\' ScratchPad!'
      n.title = 'Welcome'
      n.user = @u
      n.save

      n = Page.new :slug => 'about'
      n.title = 'About Us'
      n.user = @u
      n.nodes << Text.first << List.first
      n.save

      n = Comment.new
      n.title = 'My Awesome Comment'
      n.user = @u
      n.nodes << Text.first << Table.first
      n.save
    end

    should 'not break' do
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
    end
  end
end
