class splunk_qd::profile::search(
  Boolean $manage_addons  = true,
  String  $version        = undef,
  String  $build          = undef,
  Array   $addons         = [],
) {

  # Declaring Class[splunk:params] here is how control which version of Splunk
  # is downloaded and installed.
  class { 'splunk::params':
    version => $version,
    build   => $build,
  }

  # The class that actually sets up Splunk Enterprise is set here to manage the
  # password file so we know the admin password so we can long in and don't be
  # concerned over it is implying we're going to always install the lasets
  # release, the version downloaded is dictaed by Class[splunk::params] so
  # packages will only upgrade if you specify a newer version parameter there.
  class { 'splunk::enterprise':
    package_ensure  => latest,
    manage_password => true,
  }

  # Its safe to interate over an empty array, effectively a noop if you haven't
  # passed in a list of addons to be managed but if you have and just simply
  # don't wish to manage them temporarily then set $manage_addons to false.
  if $manage_addons {
    $addons.each |$addon| {
      splunk::addon { $addon['name']:
        splunkbase_source => "puppet:///modules/splunk_qd/addons/${addon['filename']}",
        inputs            => $addon['inputs'],
        notify            =>  Class['splunk::enterprise::service'],
      }
    }
  }
}
