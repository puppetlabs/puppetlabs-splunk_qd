plan splunk_qd() {

  run_plan('splunk_qd::search')
  run_plan('splunk_qd::forward')
}
