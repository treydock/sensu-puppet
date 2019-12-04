require 'spec_helper_acceptance'

describe 'sensu_role', if: RSpec.configuration.sensu_full do
  node = hosts_as('sensu_backend')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_role { 'test':
        rules => [{'verbs' => ['get','list'], 'resources' => ['checks']}],
      }
      sensu_role { 'test-api':
        rules    => [{'verbs' => ['get','list'], 'resources' => ['checks']}],
        provider => 'sensu_api',
      }
      EOS

      if RSpec.configuration.sensu_use_agent
        site_pp = "node 'sensu_backend' { #{pp} }"
        puppetserver = hosts_as('puppetserver')[0]
        create_remote_file(puppetserver, "/etc/puppetlabs/code/environments/production/manifests/site.pp", site_pp)
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0,2]
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0]
      else
        # Run it twice and test for idempotency
        apply_manifest_on(node, pp, :catch_failures => true)
        apply_manifest_on(node, pp, :catch_changes  => true)
      end
    end

    it 'should have a valid role' do
      on node, 'sensuctl role info test --format json' do
        data = JSON.parse(stdout)
        expect(data['rules']).to eq([{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => nil}])
      end
    end

    it 'should have a valid role using API' do
      on node, 'sensuctl role info test-api --format json' do
        data = JSON.parse(stdout)
        expect(data['rules']).to eq([{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => nil}])
      end
    end
  end

  context 'update role' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_role { 'test':
        rules => [
          {'verbs' => ['get','list'], 'resources' => ['*'], resource_names => ['foo']},
          {'verbs' => ['get','list'], 'resources' => ['checks'], resource_names => ['bar']},
        ],
      }
      sensu_role { 'test-api':
        rules => [
          {'verbs' => ['get','list'], 'resources' => ['*'], resource_names => ['foo']},
          {'verbs' => ['get','list'], 'resources' => ['checks'], resource_names => ['bar']},
        ],
        provider => 'sensu_api',
      }
      EOS

      if RSpec.configuration.sensu_use_agent
        site_pp = "node 'sensu_backend' { #{pp} }"
        puppetserver = hosts_as('puppetserver')[0]
        create_remote_file(puppetserver, "/etc/puppetlabs/code/environments/production/manifests/site.pp", site_pp)
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0,2]
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0]
      else
        # Run it twice and test for idempotency
        apply_manifest_on(node, pp, :catch_failures => true)
        apply_manifest_on(node, pp, :catch_changes  => true)
      end
    end

    it 'should have a valid role with updated propery' do
      on node, 'sensuctl role info test --format json' do
        data = JSON.parse(stdout)
        expect(data['rules'].size).to eq(2)
        expect(data['rules'][0]).to eq({'verbs' => ['get','list'], 'resources' => ['*'], 'resource_names' => ['foo']})
        expect(data['rules'][1]).to eq({'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['bar']})
      end
    end

    it 'should have a valid role with updated propery using API' do
      on node, 'sensuctl role info test-api --format json' do
        data = JSON.parse(stdout)
        expect(data['rules'].size).to eq(2)
        expect(data['rules'][0]).to eq({'verbs' => ['get','list'], 'resources' => ['*'], 'resource_names' => ['foo']})
        expect(data['rules'][1]).to eq({'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['bar']})
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_role { 'test': ensure => 'absent' }
      sensu_role { 'test-api': ensure => 'absent', provider => 'sensu_api' }
      EOS

      if RSpec.configuration.sensu_use_agent
        site_pp = "node 'sensu_backend' { #{pp} }"
        puppetserver = hosts_as('puppetserver')[0]
        create_remote_file(puppetserver, "/etc/puppetlabs/code/environments/production/manifests/site.pp", site_pp)
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0,2]
        on node, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0]
      else
        # Run it twice and test for idempotency
        apply_manifest_on(node, pp, :catch_failures => true)
        apply_manifest_on(node, pp, :catch_changes  => true)
      end
    end

    describe command('sensuctl role info test'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
    describe command('sensuctl role info test-api'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

