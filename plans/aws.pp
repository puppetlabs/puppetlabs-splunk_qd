plan splunk_qd::aws() {

  #$results = run_task('amazon_aws::ec2_aws_run_instances', 'local', {'image_id' => 'ami-01ed306a12b7d1c96', 'key_name' => 'cody-laptop', 'security_group_ids' => 'sg-9c5b6aec', 'instance_type' => 't2.medium', 'subnet_id' => 'subnet-a697fced', 'min_count' => '1', 'max_count' => '1'})
  #$instance = $results.first().value()['instances'][0]['instance_id']
  $instance = 'i-031261325e953677d'
  run_task('amazon_aws::ec2_aws_create_tags', 'local', {
    'resources' => $instance,
    'tags' => '{ resource_type: instance, tags: [{ key: Name, value: MyGroovyInstance }]}'
    }
  )
}
