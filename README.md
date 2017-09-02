# ServiceVariables

_Service-wide_ Redis backed configuration variables which can be edited while your application is running. This is particularly useful for 12 factor apps which can scale arbitrarily but need centralized configuration. Data types, defaults and boundaries can all be specified.

_Note:_ this was implemented on Redis 3.

## Install
```bash
gem install service_variables
```

## Usage

You will want to create a configuration object where you can configure the Redis endpoint and the define configuration variables.

```ruby
require 'service_variables'

module App
  class Config
    extends ServiceVariables

    # redis_client [Required] Give the ServiceConfig object a Redis client to store values.
    # redis_key    [Optional] Specify a redis key if you have multiple of these
    #                         objects using the same Redis instance.
    configure redis_client: Redis.new(url: ENV.fetch('REDIS_URL'))
              redis_key: 'special_key'

    boolean_option :foo, default: false
    integer_option :bar, default: 10, min: 1, max: 100
    float_option   :baz, default: 3.0, min: 1.0, max: 5.0
    string_option  :boo, default: 'fizz', enum: ['fizz', 'fuzz']

    # If the default param is not given, `nil` is assumed.
    # If boundary or enum params are not given, these checks are ignored.
  end
end
```

In your application you can then call or edit values.

```ruby
App::Config.foo #=> false
App::Config.foo = true
App::Config.foo #=> true

App::Config.bar = 1_000 #=> throws InvalidValueError, 'Value too large. max = 1000'
```

## Testing

```bash
# spin up redis locally
docker run --rm -d -p 6379:6379 redis

# run spec
bundle exec rspec spec
```

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/coinbase/service_variables.

## License
The gem is available open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
