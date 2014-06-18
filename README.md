puppet-plone
============

A set of puppet modules for installing and maintaining plone like a boss.

Example for installing two Plone standalone instances:
```
class { "plone::install":
  instances => { 
     client0 => { port => '8080' },
     client1 => { port => '8081' },
  }
}
```

Installing a zeo client:
```
class { "plone::install":
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
class { "plone::install":
  type => 'zeo',
  instances => {
     client0 => { port => '8080' }
  }
}
```

Installing a ZRS Primary server (with IP 10.0.0.1):

```
class { "plone::install":
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
class { "plone::install":
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

