plan profiles::splunk() {

  run_plan('profiles::splunk::search')
  run_plan('profiles::splunk::forward')
}
