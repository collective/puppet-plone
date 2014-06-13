# zrs.pp

class plone::zrs (
                ) {

  package { ["python-pip", "python-dev"]:
    ensure => installed,
  }

  package { "zc.zrs":
    ensure => installed,
    provider => pip,
  }

}

