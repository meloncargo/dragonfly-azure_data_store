require 'dragonfly/azure_data_store/version'

Dragonfly::App.register_datastore(:azure) { Dragonfly::AzureDataStore }

module Dragonfly
  class AzureDataStore
    attr_accessor :account_name, :access_key

    def initialize(opts = {})
      @account_name = opts[:account_name]
      @access_key = opts[:access_key]
    end

    def write(content, opts = {})
    end

    def read(uid)
    end

    def destroy(uid)
    end
  end
end
