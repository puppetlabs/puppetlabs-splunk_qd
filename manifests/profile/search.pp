class splunk_qd::profile::search(
  String[1]           $version,
  String[1]           $build,
  Boolean             $manage_addons     = true,
  Array               $addons            = [],
  Boolean             $ui_ssl            = false,
  Hash                $ssl               = {},
  String[1]           $passwd_hash       = '$6$E4XR.g0Sq.2JvbgT$me1K9oruJuXG09NSDv2I0wCKl9DS4ETv/XY5YqyZM5ctf.cp06JSN6x.MG2Y0lJ9zLfY6zpMn6GJNo.9O4cWH/',
  Optional[String[1]] $addon_source_path = undef
) {

  # Declaring Class[splunk:params] here is how control which version of Splunk
  # is downloaded and installed.
  class { 'splunk::params':
    version => $version,
    build   => $build,
  }

  # The class that actually installs Splunk Enterprise is set to manage the
  # initial root password so we can login immediately after installation. The
  # use of "package_ensure => latest" in this context does not actually upgrade
  # the install to the latest available version, this is actually managed by
  # which version and build parameters you set
  class { 'splunk::enterprise':
    package_ensure => latest,
    seed_password  => true,
    password_hash  => $passwd_hash,
    web_httpport   => $ui_ssl ? {
      true    => 443,
      default => 8000,
    }
  }

  # Keep all the SSL configuration logic in its own class because there is a
  # good amount of it
  if $ui_ssl {
    class { 'splunk_qd::profile::search::ssl':
      mode               => $ssl['ui_ssl_mode'],
      registration_email => $ssl['ui_ssl_reg_email'],
      registration_fqdn  => $ssl['ui_ssl_reg_fqdn'],
      test               => $ssl['ui_ssl_test'],
    }
  }

  # Redirect where add-ons are obtained if someone wants to built out a
  # testdrive with those not included in the module
  if $addon_source_path {
    $_addon_source_path = $addon_source_path
  } else {
    $_addon_source_path = 'puppet:///modules/splunk_qd/addons'
  }

  # It's safe to interate over an empty array, effectively a noop if you haven't
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
            ensure  => present,
            path    =>  "${splunk::params::enterprise_homedir}/etc/apps/${addon['name']}/local/${values['filename']}",
            section => $values['section'],
            setting => $setting,
            value   => $values['value'],
          }
        }
      }
    }
  }
}
