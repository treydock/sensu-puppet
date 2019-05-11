require 'spec_helper_acceptance_windows' if Gem.win_platform?

describe 'sensu::agent class', if: Gem.win_platform? do
  context 'default' do
    pp = <<-EOS
    class { '::sensu': }
    class { '::sensu::agent':
      package_source => 'https://s3-us-west-2.amazonaws.com/sensu.io/sensu-go/5.7.0/sensu-go-agent_5.7.0.2380_en-US.x64.msi',
      backends       => ['sensu_backend:8081'],
      config_hash    => {
        'name' => 'sensu_agent',
      }
    }
    EOS

    File.open('C:\manifest-agent.pp', 'w') { |f| f.write(pp) }
    puts "C:\manifest-agent.pp"
    puts File.read('C:\manifest-agent.pp')
    describe command('puppet apply --debug C:\manifest-agent.pp') do
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe service('SensuAgent') do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
