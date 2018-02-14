# Dragonfly::AzureDataStore

Microsoft Azure data store for use with the
[Dragonfly](http://github.com/markevans/dragonfly) gem.

## Installation

```ruby
gem 'dragonfly-azure_data_store'
```

## Usage

Configuration (remember the require)

```ruby
require 'dragonfly/azure_data_store'

Dragonfly.app.configure do
  # ...

  datastore :azure, account_name: ENV['AZURE_ACCOUNT_NAME'],
                    container_name: ENV['AZURE_CONTAINER_NAME'],
                    access_key: ENV['AZURE_ACCESS_KEY']

  # ...
end
```

### Available configuration options

```ruby
:account_name
:container_name
:access_key
:url_scheme           # defaults to "http"
:url_host             # defaults to "<account_name>.blob.core.windows.net"
:root_path            # store all content under a subdirectory - uids will be relative to this - defaults to nil
:store_meta           # store metadata info in azure. Defaults to true
:legacy_meta          # activate only if file store was used before and want to load old `.meta.yml` generated files from azure storage.
```

### Serving directly from Azure

You can get the Azure url using

```ruby
Dragonfly.app.remote_url_for('some/uid')
```

or

```ruby
my_model.attachment.remote_url
```

or with an https url:

```ruby
my_model.attachment.remote_url(scheme: 'https')   # also configurable for all urls with 'url_scheme'
```

or with a custom host:

```ruby
my_model.attachment.remote_url(host: 'custom.domain')   # also configurable for all urls with 'url_host'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/meloncargo/dragonfly-azure_data_store. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org)
code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dragonfly::AzureDataStore project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/meloncargo/dragonfly-azure_data_store/blob/master/CODE_OF_CONDUCT.md).
