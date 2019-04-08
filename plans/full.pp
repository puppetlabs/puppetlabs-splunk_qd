plan splunk_qd::full() {

  run_plan('splunk_qd::search')
  run_plan('splunk_qd::forward')
}
