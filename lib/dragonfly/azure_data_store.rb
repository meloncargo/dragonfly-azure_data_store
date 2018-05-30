require 'dragonfly'
require 'azure/storage/blob'
require 'yaml'

Dragonfly::App.register_datastore(:azure) { Dragonfly::AzureDataStore }

module Dragonfly
  class AzureDataStore
    attr_accessor :account_name, :access_key, :container_name, :root_path,
                  :url_scheme, :url_host, :store_meta, :legacy_meta

    def initialize(opts = {})
      @account_name = opts[:account_name]
      @access_key = opts[:access_key]
      @container_name = opts[:container_name]
      @root_path = opts[:root_path]
      @url_scheme = opts[:url_scheme] || 'http'
      @url_host = opts[:url_host]
      @store_meta = opts[:store_meta].nil? ? true : opts[:store_meta]
      @legacy_meta = opts[:legacy_meta]
    end

    def write(content, _opts = {})
      filename = path_for(content.name || 'file')
      path = full_path(filename)
      options = {}
      options[:metadata] = content.meta if store_meta
      content.file do |f|
        storage.create_block_blob(container_name, path, f, options)
      end
      filename
    end

    def read(uid)
      path = full_path(uid)
      result, body = storage.get_blob(container_name, path)
      meta = result.metadata
      meta = meta_from_file(path) if legacy_meta && (meta.nil? || meta.empty?)
      [body, meta]
    rescue Azure::Core::Http::HTTPError
      nil
    end

    # Updates metadata of file and deletes old meta file from legacy mode.
    #
    def update_metadata(uid)
      return false unless store_meta
      path = full_path(uid)
      meta = storage.get_blob(container_name, path)[0].metadata
      return false if meta.present?
      meta = meta_from_file(path)
      return false if meta.blank?
      storage.set_blob_metadata(container_name, path, meta)
      storage.delete_blob(container_name, meta_path(path))
      true
    rescue Azure::Core::Http::HTTPError
      nil
    end

    def destroy(uid)
      storage.delete_blob(container_name, full_path(uid))
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

    private

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

    def meta_path(path)
      "#{path}.meta.yml"
    end

    def meta_from_file(path)
      meta_blob = storage.get_blob(container_name, meta_path(path))
      YAML.safe_load(meta_blob[1])
    rescue Azure::Core::Http::HTTPError
      {}
    end
  end
end
