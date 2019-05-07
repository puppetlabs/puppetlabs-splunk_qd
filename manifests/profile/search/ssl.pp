class splunk_qd::profile::search::ssl inherits splunk_qd::profile::search {

  splunk_web { 'settings/enableSplunkWebSSL': value => true }
  splunk_web { 'settings/privKeyPath':
    value => '/opt/splunk/etc/auth/splunkweb/privkey.pem'
  }
  splunk_web { 'settings/serverCert':
    value => '/opt/splunk/etc/auth/splunkweb/cert.pem'
  }
}
