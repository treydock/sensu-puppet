require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

run_puppet_install_helper
install_module_dependencies
install_module
collection = ENV['BEAKER_PUPPET_COLLECTION'] || 'puppet5'
project_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

RSpec.configure do |c|
  c.add_setting :sensu_full, default: false
  c.add_setting :sensu_cluster, default: false
  # Used when testing clusters
  c.add_setting :sensu_provider, default: 'sensuctl'
  c.add_setting :sensu_enterprise_file, default: nil
  c.add_setting :sensu_test_enterprise, default: false
  c.add_setting :sensu_manage_repo, default: true
  c.add_setting :sensu_use_agent, default: false
  # Necessary to be present even though only used by Windows tests
  c.add_setting :skip_apply, default: false
  c.sensu_full = (ENV['BEAKER_sensu_full'] == 'yes' || ENV['BEAKER_sensu_full'] == 'true')
  c.sensu_cluster = (ENV['BEAKER_sensu_cluster'] == 'yes' || ENV['BEAKER_sensu_cluster'] == 'true')
  c.sensu_provider = ENV['BEAKER_sensu_provider'] unless ENV['BEAKER_sensu_provider'].nil?
  c.sensu_use_agent = (ENV['BEAKER_sensu_use_agent'] == 'yes' || ENV['BEAKER_sensu_use_agent'] == 'true')
  if ENV['SENSU_ENTERPRISE_FILE']
    enterprise_file = File.absolute_path(ENV['SENSU_ENTERPRISE_FILE'])
  else
    enterprise_file = File.join(project_dir, 'tests/sensu_license.json')
  end
  if File.exists?(enterprise_file)
    scp_to(hosts_as('sensu_backend'), enterprise_file, '/root/sensu_license.json')
    c.sensu_test_enterprise = true
  else
    c.sensu_test_enterprise = false
  end

  ci_build = File.join(project_dir, 'tests/ci_build.sh')
  secrets = File.join(project_dir, 'tests/secrets')
  if File.exists?(secrets) && (ENV['BEAKER_sensu_ci_build'] == 'yes' || ENV['BEAKER_sensu_ci_build'] == 'true')
    c.sensu_manage_repo = false
    add_ci_repo = true
  else
    c.sensu_manage_repo = true
    add_ci_repo = false
  end

  if RSpec.configuration.sensu_use_agent
    puppetserver = hosts_as('puppetserver')[0]
    setup_nodes = puppetserver
  else
    setup_nodes = hosts
  end

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install sensuclassic to ensure no conflicts
    on setup_nodes, puppet('module', 'install', 'sensu-sensuclassic'), { :acceptable_exit_codes => [0,1] }
    # Install soft module dependencies
    on setup_nodes, puppet('module', 'install', 'puppetlabs-apt', '--version', '">= 5.0.1 < 8.0.0"'), { :acceptable_exit_codes => [0,1] }
    if collection == 'puppet6'
      on setup_nodes, puppet('module', 'install', 'puppetlabs-yumrepo_core', '--version', '">= 1.0.1 < 2.0.0"'), { :acceptable_exit_codes => [0,1] }
    end
    if RSpec.configuration.sensu_test_enterprise
      on setup_nodes, puppet('module', 'install', 'puppetlabs-postgresql', '--version', '">= 6.0.0 < 7.0.0"'), { :acceptable_exit_codes => [0,1] }
    end
    ssldir = File.join(project_dir, 'tests/ssl')
    scp_to(hosts, ssldir, '/etc/puppetlabs/puppet/ssl')
    hosts.each do |host|
      on host, "puppet config set --section main certname #{host.name}"
    end

    if add_ci_repo
      scp_to(hosts, ci_build, '/tmp/ci_build.sh')
      scp_to(hosts, secrets, '/tmp/secrets')
      on hosts, '/tmp/ci_build.sh'
    end
    hiera_yaml = <<-EOS
---
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "Common"
    path: "common.yaml"
EOS
    common_yaml = <<-EOS
---
sensu::manage_repo: #{RSpec.configuration.sensu_manage_repo}
sensu::plugins::manage_repo: true
EOS
    create_remote_file(setup_nodes, '/etc/puppetlabs/puppet/hiera.yaml', hiera_yaml)
    on setup_nodes, 'mkdir -p -m 0755 /etc/puppetlabs/puppet/data'
    create_remote_file(setup_nodes, '/etc/puppetlabs/puppet/data/common.yaml', common_yaml)

    if RSpec.configuration.sensu_use_agent
      puppetserver = hosts_as('puppetserver')[0]
      if RSpec.configuration.sensu_cluster
        server = 'sensu_backend1'
      else
        server = 'sensu_backend'
      end
      on hosts, puppet("config set --section main server #{server}")
      on puppetserver, puppet("resource package puppetserver ensure=installed")
      on puppetserver, puppet("resource service puppetserver ensure=running")
      on puppetserver, 'chmod 0644 /etc/puppetlabs/puppet/hiera.yaml'
      on puppetserver, 'chmod 0644 /etc/puppetlabs/puppet/data/common.yaml'
      create_remote_file(puppetserver, '/etc/puppetlabs/code/environments/production/manifests/site.pp', '')
      on puppetserver, "chmod 0644 /etc/puppetlabs/code/environments/production/manifests/site.pp"
    end

    # Setup Puppet Bolt
    on setup_nodes, puppet("resource package puppet-bolt ensure=installed")
    bolt_cfg = <<-EOS
modulepath: "/etc/puppetlabs/code/modules:/etc/puppetlabs/code/environments/production/modules"
ssh:
  host-key-check: false
  user: root
  password: root
EOS
    on setup_nodes, 'mkdir -p -m 0755 /root/.puppetlabs/bolt'
    create_remote_file(setup_nodes, '/root/.puppetlabs/bolt/bolt.yaml', bolt_cfg)
  end
end
