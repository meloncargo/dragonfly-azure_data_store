require 'azure/storage/blob'

Dragonfly::App.register_datastore(:azure) { Dragonfly::AzureDataStore }

module Dragonfly
  class AzureDataStore
    attr_accessor :account_name, :access_key, :container_name, :root_path,
                  :url_scheme, :url_host

    def initialize(opts = {})
      @account_name = opts[:account_name]
      @access_key = opts[:access_key]
      @container_name = opts[:container_name]
      @root_path = opts[:root_path]
      @url_scheme = opts[:url_scheme] || 'http'
      @url_host = opts[:url_host]
    end

    def write(content, _opts = {})
      blob = nil
      filename = path_for(content.name || 'file')
      content.file do |f|
        blob = storage.create_block_blob(
          container.name, full_path(filename), f
        )
      end
      filename
    end

    def read(uid)
      blob = storage.get_blob(container.name, full_path(uid))
      [blob[1], blob[0].properties]
    rescue Azure::Core::Http::HTTPError
      nil
    end

    def destroy(uid)
      storage.delete_blob(container.name, full_path(uid))
      true
    rescue Azure::Core::Http::HTTPError
      false
    end

    def url_for(uid, opts = {})
      scheme = opts[:scheme] || url_scheme
      host   = opts[:host]   || url_host ||
               "#{account_name}.blob.core.windows.net"
      "#{scheme}://#{host}/#{container_name}/#{full_path(uid)}"
    end

    def storage
      @storage ||=
        Azure::Storage::Blob::BlobService.create(
          storage_account_name: account_name,
          storage_access_key: access_key
        )
    end

    def container
      @container ||= begin
        storage.get_container_properties(container_name)
      rescue Azure::Core::Http::HTTPError => e
        raise if e.status_code != 404
        storage.create_container(container_name)
      end
    end

    def path_for(filename)
      time = Time.now
      "#{time.strftime '%Y/%m/%d/'}#{rand(1e15).to_s(36)}_#{filename.gsub(/[^\w.]+/, '_')}"
    end

    def full_path(filename)
      File.join(*[root_path, filename].compact)
    end
  end
end
