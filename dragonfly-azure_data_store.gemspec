
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dragonfly/azure_data_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'dragonfly-azure_data_store'
  spec.version       = Dragonfly::AzureDataStore::VERSION
  spec.authors       = ['Alter Lagos']
  spec.email         = ['alagos@users.noreply.github.com']

  spec.summary       = 'dragonfly-azure_data_store'
  spec.description   = 'Dragonfly Store to be used with Azure Storage Service'
  spec.homepage      = 'https://github.com/meloncargo/dragonfly-azure_data_store'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'azure-storage-blob', '~> 1.0'
  spec.add_runtime_dependency 'dragonfly', '~> 1.0'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
