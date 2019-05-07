class splunk_qd::profile::search::ssl inherits splunk_qd::profile::search {

  splunk_web { 'settings/enableSplunkWebSSL': value => true }
  splunk_web { 'settings/privKeyPath':
    value => '/etc/letsencrypt/live/splunk-qd-head.gcp.herrig.es/privkey.pem'
  }
  splunk_web { 'settings/serverCert':
    value => '/etc/letsencrypt/live/splunk-qd-head.gcp.herrig.es/cert.pem'
  }

  class { 'letsencrypt':
    email             => 'cody@puppet.com',
    configure_epel    => true,
    cron_scripts_path => '/opt/splunk/var'
  }

  letsencrypt::certonly { 'splunk-qd-head.gcp.herrig.es':
    manage_cron          => true,
    cron_hour            => [0,12],
    cron_minute          => '30',
    cron_success_command => "/bin/systemctl ${splunk::enterprise::service_name} restart",
    suppress_cron_output => true,
  }
}
