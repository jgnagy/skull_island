# Skull Island

Work In Progress for a full-featured SDK for Kong 0.14.x (with 1.0.x details added for future development).

## Installation

Either:

```sh
gem install skull_island
```

Or add this to your Gemfile:

```ruby
gem 'skull_island',  '~>0.1'
```

Or add this to your .gemspec:

```ruby
Gem::Specification.new do |spec|
 # ...
 spec.add_runtime_dependency 'skull_island', '~> 0.1'
 # ...
end
```

## CLI Usage

Skull Island comes with an executable called `skull_island` that leverages the SDK under the hood. Learn about what is can do via `help`:

```
$ skull_island help
Commands:
  skull_island export [OPTIONS] OUTPUT_FILE  # Export the current configuration to OUTPUT_FILE
  skull_island help [COMMAND]                # Describe available commands or one specific command
  skull_island import [OPTIONS] INPUT_FILE   # Import a configuration from INPUT_FILE

Options:
  [--verbose], [--no-verbose]
```

To use the commands that interact with the Kong API, set environment variables for the required parameters:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
KONG_ADMIN_USERNAME='my-basicauth-user' \
KONG_ADMIN_PASSWORD='my-basicauth-password' \
skull_island ...
```

Note that you can skip `KONG_ADMIN_USERNAME` and `KONG_ADMIN_PASSWORD` if you aren't using a basic-auth reverse-proxy in front of the Admin API.

### Exporting

The CLI allows you to export an existing configuration to a YAML + ERB document (a YAML document with embedded Ruby). This format is helpful because it doesn't require you to know the IDs of resources, making your configuration portable.

The `export` command will default to outputting to STDOUT if you don't provide an output file location. Otherwise, simply specify the filename you'd like to export to:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island export /path/to/export.yml
```

You can also get a little more information by turning on `--verbose`:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island export --verbose /path/to/export.yml
```

### Importing

Skull Island also supports importing configurations (both partial and full) from a YAML + ERB document:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import /path/to/export.yml
```

It'll also read from STDIN if you don't specify a file path (or if you specify `-` as the path):

```
cat /path/to/export.yml | KONG_ADMIN_URL='https://api-admin.mydomain.com' skull_island import
# OR
KONG_ADMIN_URL='https://api-admin.mydomain.com' skull_island import < /path/to/export.yml
```

You can also get a little more information by turning on `--verbose`:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import --verbose /path/to/export.yml
```

Importing also supports a "dry run" functionality that shows you what it would do (but makes no changes) using `--test`:

```
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import --verbose --test /path/to/export.yml
```

## SDK Usage

The API Client requires configuration before it can be used. For now, this is a matter of calling `APIClient.configure()`, passing a Hash, with Symbols for keys:

```ruby
require 'skull_island'
include SkullIsland

APIClient.configure(
  server: 'https://api-admin.mydomain.com',
  username: 'my-basicauth-user',
  password: 'my-basicauth-password'
)
```

This assumes that a basic-auth reverse proxy sits in front of your Kong Admin API. If this isn't the case (it really should be), then just don't pass `username` and `password` and the API client will work just fine.

### The APIClient Singleton

The API client provides a few helpful methods of its own. To learn about the overall service you've connected to (via the [node information endpoint](https://docs.konghq.com/0.14.x/admin-api/#retrieve-node-information)):

```ruby
APIClient.about_service
# => {"plugins"=>...
```

It is also possible to check on the server status of the node you're accessing via the [node status endpoint](https://docs.konghq.com/0.14.x/admin-api/#retrieve-node-status):

```ruby
APIClient.server_status
# => {"database"=>{"reachable"=>true...
```

This SDK also makes use of automatic (and mostly unobtrusive) caching behind the scenes. As long as this tool is the only tool making changes to the Admin API (at least while it is being used), this should be fine. Eventually, there will be an option to disable this cache (at the cost of poor performance). For now, it is possible to query this cache and even flushed it manually when required:

```ruby
APIClient.lru_cache
# => #<SkullIsland::LRUCache:0x00007f9f1ebf3898 @max_size=1000...
APIClient.lru_cache.flush # this empties the cache and resets statistics
# => true
```

### Resources

Most value provided by this SDK is through the ability to manipulate resources managed through the Admin API. These resources almost all have a few methods in common.

For example, finder methods like these:

```ruby
# Get all instances of a resource type through `.all()`, returning a special collection class
Resources::Consumer.all
# => #<SkullIsland::ResourceCollection:0x00007f9f1e3f9b38...

# Find instances matching some criteria using `.where()`, returning the same kind of collection
Resources::Consumer.where(:username, /.*foo.*/) # finds all Consumers with a matching username
# => #<SkullIsland::ResourceCollection:0x00007f9f1e3351c0...

# Finding using other types of comparisons, like `<`
#  Here, we find all Consumers made more than an hour ago
Resources::Consumer.where(
  :created_at, (Time.now - 3600).to_datetime, comparison: :<
)
# => #<SkullIsland::ResourceCollection:0x00007f9f1e380924...

# Finder methods can also be chained
Resources::Consumer.where(:username, /.*foo.*/).and(:username, /\w{10,}/)
# => #<SkullIsland::ResourceCollection:0x00007f9f1e358964...
Resources::Consumer.where(:username, /.*foo.*/).or(:custom_id, /.*bar.*/)
# => #<SkullIsland::ResourceCollection:0x00007f9f1e568410...

# If you have the `id` of a particular resource, you can find it directly
Resources::Consumer.get('1cad3055-1027-459d-b76e-f590dc5f0071')
# => #<SkullIsland::Resources::Consumer:0x00007f9f201f6c58...
```

Once you have a resource, you can modify it:

```ruby
my_consumer = Resources::Consumer.get('1cad3055-1027-459d-b76e-f590dc5f0071')
my_consumer.username
# => "testuser"
my_consumer.tainted?
# => false
my_consumer.username = 'someuser'
my_consumer.tainted?
# => true
my_consumer.save
# => true
my_consumer.tainted?
# => false
my_consumer.username
# => "someuser"
```

Some resource types are related to others, such as `Routes` and `Services`:

```ruby
service = Resources::Services.all.first
# => #<SkullIsland::Resources::Services:0x00007f9f201f6f44...
service.routes
# => #<SkullIsland::ResourceCollection:0x00007f9f1e569e1d...
service.routes.size
# => 3
my_route = Resources::Route.new
my_route.hosts = ['example.com', 'example.org']
my_route.protocols = ['http', 'https']
my_route.strip_path = true
my_route.preserve_host = false
service.add_route!(my_route)
# => true
service.routes.size
# => 4
```

From here, the SDK mostly wraps the attributes described in the [Kong API Docs](https://docs.konghq.com/0.14.x/admin-api/). For simplicity, I'll go over the resource types and attributes this SDK supports manipulating. Rely on the API documentation to determine which attributes are required and under which conditions.

#### Certificates

```ruby
resource = Resources::Certificate.new

# These attributes can be set and read
resource.cert = '-----BEGIN CERTIFICATE-----...'    # PEM-encoded public key
resource.key  = '-----BEGIN RSA PRIVATE KEY-----...' # PEM-encoded private key
resource.snis = ['example.com', 'example.org']      # Array of names for which this cert is valid

resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
```

#### Consumers

```ruby
resource = Resources::Consumer.new

# These attributes can be set and read
resource.custom_id = 'user1' # A string
resource.username  = 'user1' # A string

resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.plugins
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3e...
```

#### Plugins

Note that this doesn't _install_ plugins; it only allows using them.

```ruby
resource = Resources::Plugin.new

# These attributes can be set and read
resource.name     = 'rate-limiting' # The name of the plugin
resource.enabled  = true            # A Boolean
resource.config   = { 'minute' => 50, 'hour' => 1000 } # A Hash of config keys and values

# Either reference related resources by ID
resource.service  = '5fd1z584-1adb-40a5-c042-63b19db49x21'
resource.service
# => #<SkullIsland::Resources::Services:0x00007f9f201f6f44...

# Or reference related resources directly
resource.consumer = Resources::Consumer.get('a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4')
resource.consumer
# => #<SkullIsland::Resources::Consumer:0x00007f9f201f6f98...

resource.route    = Resources::Route.get('1cad3055-1027-459d-b76e-f590dc5f0023')
resource.route
# => #<SkullIsland::Resources::Route:0x00007f9f201f6f98...

resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>

# The resource class itself allows the following methods as well:

# This provides a list of plugin names that are enabled
Resources::Plugin.enabled_names
# => ["response-transformer",...

# This looks up the configuration schema for a particular plugin by its name
Resources::Plugin.schema('acl')
# => {"fields"=>{"hide_groups_header"=>{"default"=>false...
```

#### Routes

```ruby
resource = Resources::Route.new

# These attributes can be set and read
resource.hosts          = ['example.com', 'example.org']
resource.protocols      = ['https']
resource.methods        = ['GET', 'POST']
resource.paths          = ['/some/path']
resource.regex_priority = 10
resource.strip_path     = false
resource.preserve_host  = true

# Either reference related resources by ID
resource.service = { 'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2' }
# Or reference related resources directly
resource.service = Resources::Service.get('4e13f54a-bbf1-47a8-8777-255fed7116f2')
resource.service
# => #<SkullIsland::Resources::Service:0x00007f9f201f6f98...

resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.updated_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.plugins
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3e...
```

#### Services

```ruby
resource = Resources::Service.new

# These attributes can be set and read
resource.protocol        = 'http'
resource.connect_timeout = 60000
resource.host            = 'example.com'
resource.port            = 80
resource.path            = '/api'
resource.name            = 'example-service'
resource.retries         = 10
resource.read_timeout    = 60000
resource.write_timeout   = 60000

resource.save

# Add a related route
my_route = Resources::Route.get(...)
resource.add_route!(my_route) # adds a route to the service
# => true

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.updated_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.routes
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3f...
resource.plugins
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3e...
```

#### Upstreams (and their Targets)

```ruby
resource = Resources::Upstream.new

# These attributes can be set and read
resource.name          = 'service.v1.xyz'
resource.hash_on       = 'none'
resource.hash_fallback = 'none'
resource.slots         = 1000
resource.healthchecks  = {
  'active' => {
    'concurrency' => 5,
    'healthy' => {
      'http_statuses' => [200, 302],
      'interval' => 0,
      'successes' => 0
    },
    'http_path' => '/',
    'timeout' => 1,
    'unhealthy' => {
      'http_failures' => 0,
      'http_statuses' => [
        429, 404, 500, 501, 502, 503, 504, 505
      ],
      'interval' => 0,
      'tcp_failures' => 0,
      'timeouts' => 0
    }
  }
}

resource.save

my_upstream_node = Resources::UpstreamTarget.new
my_upstream_node.target = '4.5.6.7:80'
my_upstream_node.weight = 15
resource.add_target!(my_upstream_node) # adds a target to the upstream
# => true

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.health # returns a Hash of all upstream targets and their health statuses
# => #<Hash...
resource.targets
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3f...
resource.target('1bef3055-1027-459d-b76e-f590dc5f0071') # get an Upstream Target by id
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
