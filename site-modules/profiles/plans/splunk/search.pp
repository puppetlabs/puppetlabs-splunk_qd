plan profiles::splunk::search(Boolean $restore = false) {

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

  if $restore {
    run_task('service::linux', $searcher, { action => 'stop', name => 'Splunkd' })
    run_command('rm -rf /opt/splunk/var/lib/splunk/defaultdb/db', $searcher, 'Nuke existing hot/warm database')
    upload_file('profiles/splunk/backups/splunk_db_backup.tar.gz', '/tmp/splunk_db_backup.tar.gz', $searcher, 'Uploading Splunk Backup Archive')
    run_command('tar -xzvf /tmp/splunk_db_backup.tar.gz -C /opt/splunk/var/lib/splunk/defaultdb', $searcher, 'Expanding Splunk Backup Archive')
    run_command('rm /tmp/splunk_db_backup.tar.gz', $searcher, 'Cleaning up Splunk Backup Archive')
    run_task('service::linux', $searcher, { action => 'start', name => 'Splunkd' })
  }

  # These files need to eventually be removed from the module and capable of
  # installing a dynamic list of addons, should look into adding to
  # puppet-splunk
  $installed = run_command('/opt/splunk/bin/splunk display app -auth admin:changeme', $searcher, '_catch_errors' => true).first['stdout'].split('\n').match(/^\S+/).flatten
  unless 'TA-puppet-report-viewer' in $installed {
    upload_file('profiles/splunk/addons/puppet-report-viewer_135.tgz', '/tmp/puppet-report-viewer_135.tgz', $searcher, 'Uploading Splunk Addon: Puppet Report Viewer')
    $rv_installed = run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-report-viewer_135.tgz', $searcher, '_catch_errors' => true)
    run_command('rm /tmp/puppet-report-viewer_135.tgz', $searcher)
  }
  unless 'TA-puppet-tasks-actionable' in $installed {
    upload_file('profiles/splunk/addons/puppet-tasks-actionable-alerts-for-splunk_101.tgz', '/tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, 'Uploading Splunk Addon: Puppet Tasks Actionable Alerts')
    $aa_installed = run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, '_catch_errors' => true)
    run_command('rm /tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher)
  }

  # While addons are managed outside of Puppet we have to do this exterally to
  # restart services, good evidence for integrating addons into module
  if true in [defined('$rv_installed'), defined('$aa_installed')] {
    run_task('service::linux', $searcher, { action => 'restart', name => 'Splunkd' })
  }
}
