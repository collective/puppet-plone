puppet-plone
============

A set of puppet modules for installing and maintaining plone like a boss.

For now, it only installs in standalone mode.

Example for installing two Plone instances:
```
class { "plone::install":
  instances => { 
     client0 => { port => '8080' }
     client1 => { port => '8081' }
  }
}
```

By default, the module installs on /srv/plone. 

