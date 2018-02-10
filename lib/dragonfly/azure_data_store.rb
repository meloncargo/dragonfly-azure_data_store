require 'azure/storage/blob'

Dragonfly::App.register_datastore(:azure) { Dragonfly::AzureDataStore }

module Dragonfly
  class AzureDataStore
    attr_accessor :account_name, :access_key, :container_name, :root_path

    def initialize(opts = {})
      @account_name = opts[:account_name]
      @access_key = opts[:access_key]
      @container_name = opts[:container_name]
      @root_path = opts[:root_path]
    end

    def write(content, opts = {})
      blob = nil
      filename = path_for(content.name || 'file')
      content.file do |f|
        blob = azure_blob_service.create_block_blob(
          container.name, full_path(filename), f
        )
        # storage.put_object(bucket_name, full_path(uid), f, full_storage_headers(headers, content.meta))
      end
      # content = File.open("test.png", "rb") { |file| file.read }
      filename
    end

    def read(uid)
    end

    def destroy(uid)
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

    # def generate_uid(name)
    #   "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{SecureRandom.uuid}/#{name}"
    # end

    def path_for(filename)
      time = Time.now
      "#{time.strftime '%Y/%m/%d/'}#{rand(1e15).to_s(36)}_#{filename.gsub(/[^\w.]+/,'_')}"
    end

    def full_path(filename)
      File.join(*[root_path, filename].compact)
    end
  end
end
