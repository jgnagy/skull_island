# Skull Island

A full-featured SDK for [Kong](https://konghq.com/kong/) 2.0.x (with support for migrating from 0.14.x, 1.1.x, 1.2.x, 1.4.x, and 1.5.x). Note that this is unofficial (meaning this project is in no way officially endorsed, recommended, or related to Kong [as a company](https://konghq.com/) or an [open-source project](https://github.com/Kong/kong)). It is also in no way related to the [pet toy company](https://www.kongcompany.com/) by the same name (but hopefully that was obvious).

![Gem](https://img.shields.io/gem/v/skull_island)
![Travis (.org)](https://img.shields.io/travis/jgnagy/skull_island)
![Depfu](https://img.shields.io/depfu/jgnagy/skull_island)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/jgnagy/skull_island)

## Installation

### CLI Tool

If you only plan on using the CLI tool, feel free to just use the Docker image:

```sh
docker pull jgnagy/skull_island
alias skull_island='docker run -it --rm -e KONG_ADMIN_URL=${KONG_ADMIN_URL:-http://host.docker.internal:8001} -u $(id -u) -v ${PWD}:${PWD} -w ${PWD} jgnagy/skull_island'
skull_island help
```

### Ruby Gem Install / SDK

Either:

```sh
gem install skull_island
```

Or add this to your Gemfile:

```ruby
gem 'skull_island',  '~> 2.0'
```

Or add this to your .gemspec:

```ruby
Gem::Specification.new do |spec|
 # ...
 spec.add_runtime_dependency 'skull_island', '~> 2.0'
 # ...
end
```

## CLI Usage

Skull Island comes with an executable called `skull_island` that leverages the SDK under the hood. Learn about what it can do via `help`:

```sh
$ skull_island help
Commands:
  skull_island export [OPTIONS] [OUTPUT|-]             # Export the current configuration to OUTPUT
  skull_island help [COMMAND]                          # Describe available commands or one specific command
  skull_island import [OPTIONS] [INPUT|-]              # Import a configuration from INPUT
  skull_island migrate [OPTIONS] [INPUT|-] [OUTPUT|-]  # Migrate an older config from INPUT to OUTPUT
  skull_island reset                                   # Fully reset a gateway (removing all config)
  skull_island version                                 # Display the current installed version of skull_island

Options:
  [--verbose], [--no-verbose]
```

To use the commands that interact with the Kong API, set environment variables for the required parameters:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
KONG_ADMIN_USERNAME='my-basicauth-user' \
KONG_ADMIN_PASSWORD='my-basicauth-password' \
skull_island ...
```

Note that you can skip `KONG_ADMIN_USERNAME` and `KONG_ADMIN_PASSWORD` if you aren't using a basic-auth reverse-proxy in front of the Admin API.

Also note that if you're having SSL issues (such as with a private CA), you can have Ruby make use of a custom CA public key using `SSL_CERT_FILE`:

```sh
SSL_CERT_FILE=/path/to/cabundle.pem \
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
KONG_ADMIN_USERNAME='my-basicauth-user' \
KONG_ADMIN_PASSWORD='my-basicauth-password' \
skull_island ...
```

### Exporting

The CLI allows you to export an existing configuration to a YAML + ERB document (a YAML document with embedded Ruby). This format is helpful because it doesn't require you to know the IDs of resources, making your configuration portable.

The `export` command will default to outputting to STDOUT if you don't provide an output file location. Otherwise, simply specify the filename you'd like to export to:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island export /path/to/export.yml
```

You can also get a little more information by turning on `--verbose`:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island export --verbose /path/to/export.yml
```

Exporting, by default, exports the entire configuration of a Kong gateway, but will strip out special meta-data tags added by Skull Island to track projects. If, instead, you'd like to export **only** the configuration for a specific project, you can add `--project foo` (where `foo` is the name of your project) to export only those resources associated with it and maintain the special key in the exported YAML.

#### Exporting Credentials

For most credential types, exporting works as expected (you'll see the plaintext value in the exported YAML). With `BasicauthCredential`s, however, this is not the case. This isn't a limitation of `skull_island`; rather, it is the [expected behavior](https://github.com/Kong/kong/issues/4237) of the Admin API developers. This tool, when exporting these credentials, can only provide the salted-SHA1 hash of the password, and it does so by wrapping it in a special `hash{}` notation. This allows `skull_island` to distinguish between changing the value to the literal string and comparing the _hashed_ values. The import process is also smart enough to compare plaintext to hashed values returned from the API for existing values, so it won't recreate credentials every run.

### Importing

Skull Island also supports importing configurations (both partial and full) from a YAML + ERB document:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import /path/to/export.yml
```

It'll also read from STDIN if you don't specify a file path (or if you specify `-` as the path):

```sh
cat /path/to/export.yml | KONG_ADMIN_URL='https://api-admin.mydomain.com' skull_island import
# OR
KONG_ADMIN_URL='https://api-admin.mydomain.com' skull_island import < /path/to/export.yml
```

You can also get a little more information by turning on `--verbose`:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import --verbose /path/to/export.yml
```

Importing also supports a "dry run" functionality that shows you what it would do (but makes no changes) using `--test`:

```sh
KONG_ADMIN_URL='https://api-admin.mydomain.com' \
skull_island import --verbose --test /path/to/export.yml
```

Note that `--test` has a high likelihood of generating errors with a complicated import if required/dependent resources do not exist.

#### Importing with Projects

Skull Island 1.2.1 introduced the ability to use a special top-level key in the configuration called `project` that uses meta-data to track which resources belong to a project. This meta-data can safely be added at another time as this tool will "adopt" otherwise matching resources into a project.

To use this functionality, either add the `project` key to your configuration file (usually directly below the `version` key) with some value that will be unique on your gateway, or use `--project foo` (where `foo` is the name of your project) as a CLI flag.

When using the `project` feature of Skull Island, the CLI tool will automatically clean up old resources no longer found in your config file. This is, in fact, the _only_ circumstance under which this tool actually removes resources. Use this feature with care, as it can delete large swaths of your configuration if used incorrectly. It is **critical** that this value is unique since this project functionality is used to delete resources.

### Migrating

With Skull Island, it is possible to migrate a configuration from a 0.14.x, 1.1.x, 1.2.x, 1.4.x, or 1.5.x gateway to the most recent compatible gateway. If you have a previous export, you can just run `skull_island migrate /path/to/export.yml` and you'll receive a 2.0 compatible config on standard out. If you'd prefer, you can have that config written to a file as well (just like the export command) like so:

```sh
skull_island migrate /path/to/export.yml /output/location/migrated.yml
```

While this hasn't been heavily tested for all possible use-cases, any configuration generated or usable by the `'~> 0.14'`, `'~> 1.2'`, or `~> 1.4` version of this gem should safely convert using the migration command. This tool also makes no guarantees about plugin functionality, configuration compatibility across versions, or that the same plugins are installed and available in your newer gateway. It should go without saying that you should **test and confirm** that all of your functionality was successfully migrated.

If you don't have a previous export, you'll need to install an older version of this gem using something like `gem install --version '~> 0.14' skull_island`, then perform an `export`, then you can switch back to the latest version of the gem for migrating and importing.

While it would be possible to make migration _automatic_ for the `import` command, `skull_island` intentionally doesn't do this to avoid the appearance that the config is losslessly compatible across versions. In reality, the newer config version has additional features (like tagging) that are used heavily by skull_island. It makes sense to this author to maintain the migration component and the normal functionality as distinct features to encourage the use of the newer capabilities in 1.1 and beyond. That said, Skull Island does allow 1.1, 1.2, and 1.4 version configurations to be applied to 2.0 gateways, but not the opposite.

### Reset A Gateway

Skull Island can completely clear the configuration from a Kong instance using the `reset` command. **THIS COMMAND WILL COMPLETELY CLEAR YOUR CONFIGURATION!** Since this is a pretty serious command, it requires you to include `--force`, otherwise it simply exits with an error.

Fully resetting a gateway looks like this:

```sh
skull_island reset --force
```

You can, of course, include `--verbose` to see `skull_island` do its work, though the output may be slightly misleading because of the cascading nature of deletions (e.g., deleting a Service will delete all Routes associated with it automatically).

You can also restrict the reset to just resources associated with a particular project using the `--project` flag:

```sh
skull_island reset --force --project foo
```

This assumes the project is called `foo`.

### Check Installed Version

If you're wondering what version of `skull_island` is installed, use:

```sh
$ skull_island version

SkullIsland Version: 2.0.0
```

### File Format

The import/export/migrate CLI functions produce YAML with support for embedded Ruby ([ERB](https://ruby-doc.org/stdlib-2.5.3/libdoc/erb/rdoc/ERB.html)). The file is structured like this (as an example):

```yaml
---
version: '2.0'
project: FooV2
certificates: []
ca_certificates:
- cert: |-
    -----BEGIN CERTIFICATE-----
    MIIFUzCCA...
    -----END CERTIFICATE-----
consumers:
- username: foo
  custom_id: foo
  acls:
  - group: searchusers
  credentials:
    key-auth:
    - key: q90r8908w09rqw9jfj09jq0f8y389
    basic-auth:
    - username: foo
      password: bar
upstreams: []
services:
- name: apidocs
  protocol: https
  host: api.example.com
  port: 443
  path: "/v2/api-docs"
  routes:
  - paths:
    - "/api-docs"
    protocols:
    - http
    - https
    strip_path: true
    preserve_host: false
- name: search_api
  retries: 5
  protocol: https
  host: api.example.com
  port: 3737
  connect_timeout: 30000
  write_timeout: 30000
  read_timeout: 30000
  routes:
  - methods:
    - POST
    paths:
    - "/v2/search"
    protocols:
    - http
    - https
    regex_priority: 0
    strip_path: true
    preserve_host: false
plugins:
- name: key-auth
  enabled: true
  config:
    anonymous: ''
    hide_credentials: false
    key_in_body: false
    key_names:
    - x-api-key
    run_on_preflight: true
  service: "<%= lookup :service, 'search_api' %>"
- name: acl
  enabled: true
  config:
    hide_groups_header: false
    whitelist:
    - searchusers
  service: "<%= lookup :service, 'search_api' %>"
```

All top-level keys (other than `version` and `project`) require an Array as a parameter, either by providing a list of entries or an empty Array (`[]`), or they can be omitted entirely which is the same as providing an empty Array. The above shows how to use the `lookup()` function to refer to another resource. This "looks up" the resource type (`service` in this case) by `name` (`search_api` in this case) and resolves its `id`. This function can also be used to lookup a `route` or `upstream` by its `name`, or a `consumer` by its `username`. Note that Kong itself doesn't _require_ `route` resources to have unique names, so you'll need to enforce that practice yourself for `lookup` to be useful for Routes.

Note that while this configuration looks a lot like the [DB-less](https://docs.konghq.com/1.4.x/db-less-and-declarative-config/) configuration (and even may, at times, be interchangeable), this is merely a coincidence. **Skull Island doesn't support the DB-less mode for Kong.** This may potentially change in the future, but for now it is not a goal of this project.

#### Embedded Ruby

While technically _any_ Ruby is valid, the following are pretty helpful for templating your YAML files:

* `lookup(:service, 'foo')` -  This function resolves the ID of a `service` named `foo`. Lookup supports `:consumer` (looking up the `username` attribute), `:service`, `:route`, or `:upstream` (resolving the `name` attribute).

* `ENV.fetch('VARIABLE_NAME', 'default value')` - This allows looking up the environment variable `VARIABLE_NAME` and using its value, or, if it isn't defined, it uses `default value` as the value. With this we could change `host: api.example.com` to `host: <%= ENV.fetch('API_HOST', 'api.example.com') %>`. With this, if `API_HOST` is provided, it'll use that, otherwise it will default to `api.example.com`. This is especially helpful for sensitive information; you can version control the configuration but pass in things like credentials via environment variables at runtime.

Note also that 1.4.x and beyond of Skull Island support two phases of embedded ruby: first, a simple phase that treats the **entire file** as just text, allowing you to use the full power of ruby for things like loops, conditional logic, and more; the second phase is applied for individual attributes within the rendered YAML document. This is where the `lookup()` function above is used.

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

This SDK also makes use of automatic (and mostly unobtrusive) caching behind the scenes. As long as this tool is the only tool making changes to the Admin API (at least while it is being used), this should be fine. Eventually, there will be an option to disable this cache (at the cost of poor performance). For now, it is possible to query this cache and even flush it manually when required:

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
service = Resources::Service.all.first
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

From here, the SDK mostly wraps the attributes described in the [Kong API Docs](https://docs.konghq.com/2.0.x/admin-api/). For simplicity, I'll go over the resource types and attributes this SDK supports manipulating. Rely on the API documentation to determine which attributes are required and under which conditions.

#### CA Certificates

These are used by the gateway to verify upstream certificates when connecting to them via HTTPS. These are not used to allow Kong to _generate_ certificates. Thus, there is only a public key (`cert`) attribute for this resource.

```ruby
resource = Resources::CACertificate.new

# These attributes can be set and read
resource.cert = '-----BEGIN CERTIFICATE-----...' # PEM-encoded public key
resource.tags = ['production', 'example']        # Array of tags
resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
```

#### Certificates

```ruby
resource = Resources::Certificate.new

# These attributes can be set and read
resource.cert = '-----BEGIN CERTIFICATE-----...'     # PEM-encoded public key
resource.key  = '-----BEGIN RSA PRIVATE KEY-----...' # PEM-encoded private key
resource.snis = ['example.com', 'example.org']       # Array of names for which this cert is valid
resource.tags = ['production', 'example']            # Array of tags
resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
```

#### Consumers (along with their Access Control Lists and Credentials)

Note that for Consumer credentials, only [`key-auth`](https://docs.konghq.com/hub/kong-inc/key-auth/), [`jwt`](https://docs.konghq.com/hub/kong-inc/jwt/), and [`basic-auth`](https://docs.konghq.com/hub/kong-inc/basic-auth/) are currently supported.

```ruby
resource = Resources::Consumer.new

# These attributes can be set and read
resource.custom_id = 'user1'              # A string
resource.username  = 'user1'              # A string
resource.tags = ['production', 'example'] # Array of tags

resource.save

# These attributes are read-only
resource.id
# => "1cad3055-1027-459d-b76e-f590dc5f0071"
resource.created_at
# => #<DateTime: 2018-07-17T12:51:28+00:00 ((2458317j,46288s,0n),+0s,2299161j)>
resource.plugins
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3e...
resource.acls
# => #<SkullIsland::ResourceCollection:0x00007f9f1e765b3c...
resource.credentials
# => {}
resource.add_credential!(key: '932948e89e09e2989d8092') # adds a KeyauthCredential
# => true
resource.credentials['key-auth']
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3f...
resource.credentials['key-auth'].first.key
# => "932948e89e09e2989d8092"
resource.add_credential!(username: 'test', password: 'passw0rd') # adds a BasicauthCredential
# => true
resource.credentials['basic-auth']
# => #<SkullIsland::ResourceCollection:0x00007f9f1e564f3f...
resource.credentials['basic-auth'].first.username
# => "test"
resource.add_acl!(group: 'somegroup')
# => true
```

#### Plugins

Note that this doesn't _install_ plugins; it only allows using them.

```ruby
resource = Resources::Plugin.new

# These attributes can be set and read
resource.name     = 'rate-limiting'                    # The name of the plugin
resource.enabled  = true                               # A Boolean
resource.config   = { 'minute' => 50, 'hour' => 1000 } # A Hash of config keys and values
resource.tags = ['production', 'example']              # Array of tags

# Either reference related resources by ID
resource.service  = { 'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21' }
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
resource.name           = 'example_route'
resource.hosts          = ['example.com', 'example.org']
resource.protocols      = ['https']
resource.methods        = ['GET', 'POST']
resource.paths          = ['/some/path']
resource.regex_priority = 10
resource.strip_path     = false
resource.preserve_host  = true
resource.tags = ['production', 'example']

# Or, for TCP/TLS routes
resource.protocols    = ['tcp', 'tls']
resource.sources      = [
  { "ip" => "10.1.0.0/16", "port" => 1234 }
]
resource.destinations = [
  { "ip" => "10.1.0.0/16", "port" => 1234 },
  { "ip" => "10.2.2.2" },
  { "port" => 9123 }
]
resource.snis         = ['example.com', 'example.org']

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
resource.client_certificate = { 'id' => '77e32ff2-...' }
resource.connect_timeout = 60000
resource.host            = 'example.com'
resource.port            = 80
resource.path            = '/api'
resource.name            = 'example-service'
resource.retries         = 10
resource.read_timeout    = 60000
resource.write_timeout   = 60000
resource.tags = ['production', 'example']

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
resource.algorithm     = 'round-robin'
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
resource.tags = ['production', 'example']

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
