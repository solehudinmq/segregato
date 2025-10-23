# frozen_string_literal: true

require "active_record"
require "yaml"
require "concurrent"
require "logger"

require_relative "segregato/version"
require_relative "segregato/config"
require_relative "segregato/replica_connection_manager"
require_relative "segregato/error"

module Segregato
  include Segregato::Error

  # load database configuration
  Segregato::Config.load
  
  # class to use in model to write (command)
  class StrictWriteBase < ActiveRecord::Base
    self.abstract_class = true
  
    # connected to the master database
    establish_connection(Segregato::Config.master_config)

    # list of prohibited reading methods
    FORBIDDEN_READ_METHODS = [
      :find, :find_by, :where, :all, :first, :last, :limit, 
      :pluck, :exists?, :count, :sum, :average, :minimum, :maximum, :reload
    ].freeze

    # reading method is not allowed
    FORBIDDEN_READ_METHODS.each do |method_name|
      define_singleton_method(method_name) do |*args, &block|
        raise StrictWriteModelError.new(method_name)
      end
    end

    # override instance method for read operations
    def reload(*)
      raise StrictWriteModelError.new(:reload)
    end
    
    # override method .delete_all
    def self.delete_all(*args, &block)
      unscoped.delete_all(*args, &block)
    end
  end

  # class to use in the model for reading (query)
  class StrictReadBase < ActiveRecord::Base
    self.abstract_class = true

    # list of prohibited write methods
    FORBIDDEN_WRITE_METHODS = [
      :save, :save!, :update, :update!, :destroy, :destroy!, 
      :delete, :delete_all, :update_all, :create, :create!, :insert_all
    ].freeze

    # override self.connection to ensure the connection is redirected to the replica every time a read operation is called
    def self.connection
      # set the global ActiveRecord::Base connection to the next replica
      Segregato::ReplicaConnectionManager.establish_connection_to_next_replica
      
      super
    end

    # write method is not allowed
    FORBIDDEN_WRITE_METHODS.each do |method_name|
      define_singleton_method(method_name) do |*args, &block|
        raise StrictReadModelError.new(method_name)
      end
    end

    # override instance method for write operations
    FORBIDDEN_WRITE_METHODS.each do |method_name|
      define_method(method_name) do |*args, &block|
        raise StrictReadModelError.new(method_name)
      end
    end
  end
end
