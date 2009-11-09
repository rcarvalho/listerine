$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/listerine/list'
ActiveRecord::Base.class_eval { include ActiveRecord::Listerine::List }
