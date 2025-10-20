module Segregato
  module Config
    @@master_config = nil
    @@replica_configs = []

    # load configuration for master database
    def self.load(file_path = 'database.yml', env = (ENV['DB_ENV'] || 'development'))
      # check the existence of the database config file
      raise "File '#{file_path}' not found." unless File.exist?(file_path)

      # reading and parsing data from a YAML file
      full_config = YAML.load_file(file_path)[env]

      # check configuration for master database
      unless full_config && full_config['master']
        raise "Master configuration in environment '#{env}' was not found in #{file_path}."
      end

      # configuration for master database
      @@master_config = full_config['master'].freeze
      
      # configuration for replica database
      @@replica_configs = full_config.reject { |key, _| key == 'master' }.values.freeze
      
      # check configuration for replica database
      unless @@replica_configs.size > 0
        raise "Replica configuration not found in #{file_path}. Ensure there is a key other than 'master'."
      end
      
      # connection to master database
      ActiveRecord::Base.establish_connection(@@master_config)

      # logger for active record
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.logger.level = Logger::INFO
      ActiveRecord::Base.logger.info("--- MASTER connection was successfully initialized. ---")
    end

    # get master database config
    def self.master_config
      @@master_config || raise("The Master configuration has not been loaded. Call Segregato::Config.load(file_path, env) first.")
    end

    # get replica database config
    def self.replica_configs
      @@replica_configs || raise("The Replica configuration has not been loaded. Call Segregato::Config.load(file_path, env) first.")
    end
  end
end