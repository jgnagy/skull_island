# Skull Island

Work In Progress for a full-featured SDK for Kong 0.14.x (with 1.0.x details added for future development).

## Usage

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

This SDK also makes automatic (and mostly unobtrusive) caching behind the scenes. As long as this tool is the only tool making changes to the Admin API (at least while it is being used), this should be fine. Eventually, there will be an option to disable this cache (at the cost of poor performance). For now, it is possible to query this cache and even flushed it manually when required:

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
Resources::Consumer.where(:username, /.*foo.*/).and(:custom_id, 'foobar')
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
