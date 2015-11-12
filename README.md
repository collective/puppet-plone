puppet-plone
============

A set of puppet modules for installing and maintaining plone like a boss.

Required modules:
 - https://github.com/stankevich/puppet-python
 - https://github.com/example42/puppet-wget
 - https://github.com/puppetlabs/puppetlabs-concat
 - https://github.com/puppetlabs/puppetlabs-stdlib



Example for installing two Plone standalone instances:
```
class { "plone":
  instances => { 
     client0 => { port => '8080' },
     client1 => { port => '8081' },
  }
}
```

Installing a zeo client:
```
class { "plone":
  type => 'zeoclient',
  instances => {
     client0 => { port        => '8080',
                  zeo_client  => true,
                  read_only   => false,
                  zeo_address => '10.0.0.1:8100'
                }
  }
}
```

Installing a zeo server:

```
class { "plone":
  type => 'zeo',
  instances => {
     client0 => { port => '8080' }
  }
}
```

Installing a ZRS Primary server (with IP 10.0.0.1):

```
class { "plone":
  type => 'zeo',
  instances => {
     client0 => { port => '8080',
                  zrs_role => 'primary',
                  zrs_repl_host => '0.0.0.0:5000' 
                }
  }  
}
```

Installing a ZRS Secondary server replicating from the primary above:

```
class { "plone":
  type => 'zeo',
  instances => {
     client0 => { port => '8080', 
                  zrs_role => 'secondary',
                  zrs_repl_host => '10.0.0.1:5000' 
                }
  }             
} 
```


By default, the module installs on /srv/plone. 

