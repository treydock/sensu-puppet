require 'spec_helper_acceptance'

describe 'sensu_bonsai_asset', if: RSpec.configuration.sensu_full do
  node = hosts_as('sensu_backend')[0]
  context 'install bonsai asset' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'present',
        version => '1.1.0',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'present',
        version  => '0.1.0',
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

    it 'should have bonsai asset' do
      on node, 'sensuctl asset info sensu/sensu-pagerduty-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('1.1.0')
      end
    end

    it 'should have bonsai asset from API' do
      on node, 'sensuctl asset info sensu/sensu-email-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('0.1.0')
      end
    end
  end

  context 'install bonsai asset - latest' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'present',
        version => 'latest',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'present',
        version  => 'latest',
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

    it 'should have bonsai asset' do
      on node, 'sensuctl asset info sensu/sensu-pagerduty-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        upgraded = (Gem::Version.new(version) > Gem::Version.new('1.1.0'))
        expect(version).not_to eq('1.1.0')
        expect(upgraded).to eq(true)
      end
    end

    it 'should have bonsai asset using API' do
      on node, 'sensuctl asset info sensu/sensu-email-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        upgraded = (Gem::Version.new(version) > Gem::Version.new('0.1.0'))
        expect(version).not_to eq('0.1.0')
        expect(upgraded).to eq(true)
      end
    end
  end

  context 'downgrade bonsai asset' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'present',
        version => '1.1.0',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'present',
        version  => '0.1.0',
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

    it 'should have bonsai asset' do
      on node, 'sensuctl asset info sensu/sensu-pagerduty-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('1.1.0')
      end
    end

    it 'should have bonsai asset from API' do
      on node, 'sensuctl asset info sensu/sensu-email-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('0.1.0')
      end
    end
  end

  context 'upgrade bonsai asset' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'present',
        version => '1.2.0',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'present',
        version  => '0.2.0',
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

    it 'should have bonsai asset' do
      on node, 'sensuctl asset info sensu/sensu-pagerduty-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('1.2.0')
      end
    end

    it 'should have bonsai asset from API' do
      on node, 'sensuctl asset info sensu/sensu-email-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('0.2.0')
      end
    end
  end

  context 'asset purging' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'present',
        version => '1.2.0',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'present',
        version  => '0.2.0',
        provider => 'sensu_api',
      }
      resources { 'sensu_asset': purge => true }
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

    it 'should have bonsai asset' do
      on node, 'sensuctl asset info sensu/sensu-pagerduty-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('1.2.0')
      end
    end

    it 'should have bonsai asset from API' do
      on node, 'sensuctl asset info sensu/sensu-email-handler --format json' do
        data = JSON.parse(stdout)
        version = data['metadata']['annotations']['io.sensu.bonsai.version']
        expect(version).to eq('0.2.0')
      end
    end
  end

  context 'remove bonsai asset' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_bonsai_asset { 'sensu/sensu-pagerduty-handler':
        ensure  => 'absent',
      }
      sensu_bonsai_asset { 'sensu/sensu-email-handler':
        ensure   => 'absent',
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

    describe command('sensuctl asset info sensu/sensu-pagerduty-handler'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
    describe command('sensuctl asset info sensu/sensu-email-handler'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end
