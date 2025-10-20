module Segregato
  module ReplicaConnectionManager
    # using AtomicFixnum for race condition safe counters
    @@current_index = Concurrent::AtomicFixnum.new(0)

    # set connection to next replica database
    def self.next_replica_config
      # fetch configuration replica database
      replica_configs = Segregato::Config.replica_configs
      replica_count = replica_configs.size

      # get the current index
      index = @@current_index.value
      # update the current index value
      @@current_index.update { |v| (v + 1) % replica_count }
      
      # fetch replica configuration based on index position
      replica_configs[index]
    end

    # set the ActiveRecord::Base connection to the next selected replica
    def self.establish_connection_to_next_replica
      # next replica database connection
      config = next_replica_config

      # connection to next replica database
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.logger.info("--- READ connections set (Round-Robin) to: #{config['database']} on #{config['host']} ---")
    end
  end
end