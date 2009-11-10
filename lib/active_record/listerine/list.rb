module ActiveRecord
  module Listerine #:nodoc:
    module List #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def listerine(list_parent_symbol, list_collection_symbol)
          listerine_config = {}
          listerine_config[:parent] = list_parent_symbol
          listerine_config[:collection] = list_collection_symbol
          
          class_eval <<-EOV
            include ActiveRecord::Listerine::List::InstanceMethods

            def listerine_class
              ::#{self.name}
            end
            
            def listerine_parent_symbol
              "#{listerine_config[:parent]}"
            end
            
            def listerine_collection_symbol
              "#{listerine_config[:collection]}"              
            end
            
            def listerine_min_threshold
              1e-300 # we can store 1074 items (I'm rounding to 1000 to be safe) between two items in a list before we hit the threshold
            end

            before_create  :set_position_bottom
          EOV
        end
      end
      
      module InstanceMethods
        def move_to(position) # position is 1-based index based on location in the list. This position is not the same as what is stored in the +position+ column.
          pos = position.to_i
          collection = self.send(listerine_parent_symbol).send(listerine_collection_symbol)
          return if collection.count == 1 # don't move it if we only have one item in the collection
          new_pos = 0
          if pos <= 1 # Move to top
            new_pos = collection.first.position / 2.0
          elsif pos >= collection.count # Move to end if the position is the end or greater
            new_pos = collection.last.position + 1
          else # Move to somewhere in the middle of the list
            item_pos = collection[pos-1].position 
            prev_item_pos = collection[pos-2].position
            new_pos = ((item_pos - prev_item_pos) / 2.0) + prev_item_pos
          end
          listerine_class.update_all("position = #{new_pos}", "id=#{self.id}")
          cleanup_positions! if new_pos < listerine_min_threshold # once we hit this threshold we need to cleanup the positions on all the items in the list
        end
        
        def move_to_bottom
          move_to(set_position_bottom)
        end
        
        def move_to_top
          move_to(1)
        end

        def cleanup_positions!
          collection = self.send(listerine_parent_symbol).send(listerine_collection_symbol)
          collection.each_with_index do |item, idx|
            item.update_attribute(:position, idx+1)
          end
        end   
        
        private
          def set_position_bottom
            self.position = get_bottom_position
          end     

          def get_bottom_position
            collection = self.send(listerine_parent_symbol).send(listerine_collection_symbol)
            new_pos = collection.last && collection.last.position # set new position to last position
            new_pos ||= 0 # set to zero if list is empty
            new_pos += 1 # increment position
            new_pos            
          end
      end
    end
  end
end