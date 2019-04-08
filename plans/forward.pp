plan splunk_qd::forward() {

  $searcher = get_targets('searcher')
  $forwarders = get_targets('forwarders')

  $search_host = $searcher[0].host

  $forwarders.apply_prep

  apply($forwarders) {
    class { 'splunk::params':
      server  => $search_host,
      version => '7.2.5',
      build   => '088f49762779',
    }

    class { 'splunk::forwarder': package_ensure => latest, manage_password => true }
    splunk::addon { 'Splunk_TA_nix':
      splunkbase_source => 'puppet:///modules/splunk_qd/addons/splunk-add-on-for-unix-and-linux_602.tgz',
      inputs            => {
        'monitor:///var/log'       => {
          'whitelist' => '(\.log|log$|messages|secure|auth|mesg$|cron$|acpid$|\.out)',
          'blacklist' => '(lastlog|anaconda\.syslog)',
          'disabled'  => 'false'
        },
        'script://./bin/uptime.sh' =>  {
          'disabled' => 'false',
          'interval' => '86400',
          'source' => 'Unix:Uptime',
          'sourcetype' => 'Unix:Uptime'
        }
      }
    }
  }
}
