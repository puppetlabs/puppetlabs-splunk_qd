plan profiles::splunk::search() {

  $searcher = get_targets('searcher')

  $searcher.apply_prep

  #Compile the manifest block into a catalog
  apply($searcher) {
    class { 'splunk::params':
      version => '7.2.5',
      build   => '088f49762779',
    }
    class { 'splunk::enterprise': package_ensure => latest, manage_password => true }
  }

  # Should be moved into Puppet code
  upload_file('profiles/splunk/addons/puppet-report-viewer_135.tgz', '/tmp/puppet-report-viewer_135.tgz', $searcher, 'Uploading Splunk Addon: Puppet Report Viewer')
  run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-report-viewer_135.tgz', $searcher, '_catch_errors' => true)
  upload_file('profiles/splunk/addons/puppet-tasks-actionable-alerts-for-splunk_101.tgz', '/tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, 'Uploading Splunk Addon: Puppet Tasks Actionable Alerts')
  run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, '_catch_errors' => true)
}
