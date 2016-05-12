# Cookbook Name:: monit-ng
#
# Recipe:: config
#
require 'json'
monit = node['monit']
config = monit['config']

opsworks_app_empty = data_bag(DatabagsHelper::OPSWORKS_APP).empty?
opsworks_app = opsworks_app_empty ?
  node :
  search(DatabagsHelper::OPSWORKS_APP).first

environment_variables =  opsworks_app['environment']

alert = [
  {
    'name' => environment_variables['MONIT_ALERT_EMAIL']
  }
]

mail_servers = [
  {
    'hostname'  => environment_variables['MONIT_MAIL_HOST'],
    'port'      => environment_variables['MONIT_MAIL_PORT'],
    'username'  => environment_variables['MONIT_MAIL_USERNAME'],
    'password'  => environment_variables['MONIT_MAIL_PASSWORD'],
    'security'  => environment_variables['MONIT_MAIL_SECURITY']
  }
]


built_in_config_path =  value_for_platform_family(
    'rhel'    => '/etc/monit.d',
    'debian'  => '/etc/monit/conf.d',
    'default' => '/etc/monit.d'
  )


directory monit['conf_dir'] do
  owner 'root'
  group 'root'
  mode '0600'
  recursive true
  action :create
end

template monit['conf_file'] do # ~FC009
  source 'monit.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    poll_freq: config['poll_freq'],
    start_delay: config['start_delay'],
    log_file: config['log_file'],
    id_file: config['id_file'],
    state_file: config['state_file'],
    pid_file: config['pid_file'],
    mail_servers: mail_servers,
    alert: alert,
    eventqueue_dir: config['eventqueue_dir'],
    eventqueue_slots: config['eventqueue_slots'],
    listen: config['listen'],
    port: environment_variables['MONIT_PORT'],
    allow: JSON.parse(environment_variables['MONIT_ALLOW']),
    mail_from: config['mail_from'],
    mail_subject: config['mail_subject'],
    mail_msg: config['mail_message'],
    mmonit_url: config['mmonit_url'],
    conf_dir: monit['conf_dir'],
    built_in_config_path: monit['conf_dir'],
    built_in_configs: config['built_in_configs']
  )
  if Chef::VERSION.to_f >= 12
    verify do |path|
      "monit -tc #{path}"
    end
  end
end
