require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :items do |t|
      t.column :name, :string
      t.column :position, :float
      t.column :thing_id, :integer
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime      
    end

    create_table :things do |t|
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime      
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Thing < ActiveRecord::Base
  has_many :items, :order => :position    
end

class Item < ActiveRecord::Base
  belongs_to :thing
  listerine :thing, :items  
end


class ListTest < Test::Unit::TestCase
  
  def setup
    setup_db    
    @thing = Thing.create
  end

  def teardown
    teardown_db
  end  

  def test_add_some_items
    100.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end
  
    assert_equal (1..100).to_a, @thing.reload.items.map{|i| i.name.to_i}

    @thing.items.first.cleanup_positions!
    @thing.items(true).each_with_index do |item, idx|
      assert_equal idx+1, item.position
    end
  end

  def test_add_some_items_and_then_insert_in_middle
    10.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    first_item = @thing.items.first
    first_item.move_to(5) # move to position 5
    assert_equal ["2", "3", "4", "5", "1", "6", "7", "8", "9", "10"], @thing.items(true).map(&:name)
  end

  def test_add_some_items_and_then_move_from_latter_to_previous
    10.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    item = @thing.items[5]
    item.move_to(3) # move to position 3
    assert_equal ["1", "2", "6", "3", "4", "5", "7", "8", "9", "10"], @thing.items(true).map(&:name)
  end

  def test_add_some_items_and_then_insert_at_the_end
    10.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    first_item = @thing.items.first
    first_item.move_to(10) # move to end position
    assert_equal ["2", "3", "4", "5", "6", "7", "8", "9", "10", "1"], @thing.items(true).map(&:name)
  end


  def test_add_some_items_and_then_insert_beyond_the_end
    10.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    first_item = @thing.items.first
    first_item.move_to(100) # move to end position
    assert_equal ["2", "3", "4", "5", "6", "7", "8", "9", "10", "1"], @thing.items(true).map(&:name)
  end
  
  def test_move_from_one_list_to_another
    10.downto(1).each do |num|
      item = @thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    @new_thing = Thing.create
    
    10.downto(1).each do |num|
      item = @new_thing.items.create(:name => num.to_s)
      item.move_to(1)
    end

    item = @thing.items.last
    item.update_attribute(:thing_id, @new_thing.id)
    item.move_to(5)
    assert_equal ["1", "2", "3", "4", "10", "5", "6", "7", "8", "9", "10"], @new_thing.items(true).map(&:name)
  end
  

end