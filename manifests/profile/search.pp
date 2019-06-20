class splunk_qd::profile::search(
  Boolean $manage_addons                = true,
  Array $addons                         = [],
  Boolean $web_ssl                      = false,
  Hash $ssl                             = {},
  String[1] $version,
  String[1] $build,
  Optional[String[1]] $addon_source_path = undef
) {

  # Declaring Class[splunk:params] here is how control which version of Splunk
  # is downloaded and installed.
  class { 'splunk::params':
    version => $version,
    build   => $build,
  }

  # The class that actually sets up Splunk Enterprise is set here to manage the # password file so we know the admin password so we can long in and don't be
  # concerned over it is implying we're going to always install the lasets
  # release, the version downloaded is dictaed by Class[splunk::params] so
  # packages will only upgrade if you specify a newer version parameter there.
  class { 'splunk::enterprise':
    package_ensure  => latest,
    manage_password => true,
    reset_admin     => true,
    web_httpport    =>  $web_ssl ? {
      true    => 443,
      default => 8000,
    }
  }

  if $web_ssl {
    class { 'splunk_qd::profile::search::ssl':
      mode               => $ssl['mode'],
      registration_email => $ssl['reg_email'],
      registration_fqdn  => $ssl['reg_fqdn'],
    }
  }

  if $addon_source_path {
    $_addon_source_path = $addon_source_path
  } else {
    $_addon_source_path = 'puppet:///modules/splunk_qd/addons'
  }

  # Its safe to interate over an empty array, effectively a noop if you haven't
  # passed in a list of addons to be managed but if you have and just simply
  # don't wish to manage them temporarily then set $manage_addons to false.
  if $manage_addons {
    $addons.each |$addon| {
      splunk::addon { $addon['name']:
        splunkbase_source => "${_addon_source_path}/${addon['filename']}",
        inputs            => $addon['inputs'],
        notify            =>  Class['splunk::enterprise::service'],
      }

      # If the add-on has a set of settings that are set outside of inputs.conf
      # then they should be added to the `additional_settings` hash,
      # puppet/splunk doesn't currently understand all files that configuration
      # can be storred in so this is implemented with raw usage of ini_setting.
      if $addon['additional_settings'] {
        $addon['additional_settings'].each |$setting, $values| {
          ini_setting { "${addon['name']}_${values['filename']}_${values['section']}_${setting}":
            ensure         => present,
            path           =>  "${splunk::params::enterprise_homedir}/etc/apps/${addon['name']}/local/${values['filename']}",
            section        => $values['section'],
            setting        => $setting,
            value          => $values['value'],
          }
        }
      }
    }
  }
}
