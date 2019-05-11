require 'spec_helper'

describe 'sensu::agent', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'with default values for all parameters' do
        # Unknown bug in rspec-puppet fails to compile windows paths
        # when they are used for file source of sensu_ssl_ca, issue with windows mocking
        if facts[:os]['family'] != 'windows'
          it { should compile.with_all_deps }
        end

        it { should contain_class('sensu')}
        it { should contain_class('sensu::agent')}

        if facts[:os]['family'] == 'windows'
          sensu_agent_exe = "C:\\Program Files\\sensu\\sensu-agent\\bin\\sensu-agent.exe"
          it {
            should contain_exec('install-agent-service').with({
              'command' => "C:\\windows\\system32\\cmd.exe /c \"\"#{sensu_agent_exe}\" service install --config-file \"#{platforms[facts[:osfamily]][:agent_config_path]}\" --log-file \"#{platforms[facts[:osfamily]][:log_file]}\"\"",
              'unless'  => 'C:\\windows\\system32\\sc.exe query SensuAgent',
              'before'  => 'Service[sensu-agent]',
              'require' => [
                'Package[sensu-go-agent]',
                'File[sensu_agent_config]',
              ],
            })
          }
        else
          it { should_not contain_exec('install-agent-service') }
        end
        it { should_not contain_archive('sensu-go-agent.msi') }

        it {
          should contain_package('sensu-go-agent').with({
            'ensure'  => 'installed',
            'name'    => platforms[facts[:osfamily]][:agent_package_name],
            'source'  => nil,
            'before'  => 'File[sensu_etc_dir]',
            'require' => platforms[facts[:osfamily]][:package_require],
          })
        }

        agent_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |backend-url:
          |- wss://localhost:8081
          |trusted-ca-file: #{platforms[facts[:osfamily]][:ca_path_yaml]}
        END

        it {
          should contain_file('sensu_agent_config').with({
            'ensure'  => 'file',
            'path'    => platforms[facts[:osfamily]][:agent_config_path],
            'content' => agent_content,
            'owner'   => platforms[facts[:osfamily]][:user],
            'group'   => platforms[facts[:osfamily]][:group],
            'mode'    => platforms[facts[:osfamily]][:agent_config_mode],
            'require' => 'Package[sensu-go-agent]',
            'notify'  => 'Service[sensu-agent]',
          })
        }

        it {
          should contain_service('sensu-agent').with({
            'ensure'    => 'running',
            'enable'    => true,
            'name'      => platforms[facts[:osfamily]][:agent_service_name],
            'subscribe' => 'Class[Sensu::Ssl]',
          })
        }
      end

      context 'when package_source defined as URL' do
        let(:params) {{ package_source: 'https://foo/sensu-go-agent.msi' }}
        if facts[:os]['family'] == 'windows'
          it {
            should contain_archive('sensu-go-agent.msi').with({
              'source' => 'https://foo/sensu-go-agent.msi',
              'path'   => 'C:\\\\sensu-go-agent.msi',
              'extract'=> 'false',
              'cleanup'=> 'false',
              'before' => 'Package[sensu-go-agent]',
            })
          }
          it { should contain_package('sensu-go-agent').with_source('C:\\\\sensu-go-agent.msi') }
        else
          it { should_not contain_archive('sensu-go-agent.msi') }
          it { should contain_package('sensu-go-agent').without_source }
        end
      end

      context 'when package_source defined as puppet' do
        let(:params) {{ package_source: 'puppet:///modules/profile/sensu-go-agent.msi' }}
        if facts[:os]['family'] == 'windows'
          it {
            should contain_file('sensu-go-agent.msi').with({
              'ensure' => 'file',
              'source' => 'puppet:///modules/profile/sensu-go-agent.msi',
              'path'   => 'C:\\\\sensu-go-agent.msi',
              'before' => 'Package[sensu-go-agent]',
            })
          }
          it { should contain_package('sensu-go-agent').with_source('C:\\\\sensu-go-agent.msi') }
        else
          it { should_not contain_archive('sensu-go-agent.msi') }
          it { should contain_package('sensu-go-agent').without_source }
        end
      end

      context 'when package_source is local' do
        let(:params) {{ package_source: 'C:\\sensu-go-agent.msi' }}
        it { should_not contain_archive('sensu-go-agent.msi') }
        if facts[:os]['family'] == 'windows'
          it { should contain_package('sensu-go-agent').with_source('C:\\sensu-go-agent.msi') }
        else
          it { should contain_package('sensu-go-agent').without_source }
        end
      end

      context 'with use_ssl => false' do
        let(:pre_condition) do
          "class { 'sensu': use_ssl => false }"
        end

        agent_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |backend-url:
          |- ws://localhost:8081
        END

        it {
          should contain_file('sensu_agent_config').with({
            'ensure'    => 'file',
            'path'      => platforms[facts[:osfamily]][:agent_config_path],
            'content'   => agent_content,
            'owner'     => platforms[facts[:osfamily]][:user],
            'group'     => platforms[facts[:osfamily]][:group],
            'mode'      => platforms[facts[:osfamily]][:agent_config_mode],
            'show_diff' => 'true',
            'require'   => 'Package[sensu-go-agent]',
            'notify'    => 'Service[sensu-agent]',
          })
        }

        it { should contain_service('sensu-agent').without_notify }
      end

      context 'with show_diff => false' do
        let(:params) {{ :show_diff => false }}
        it { should contain_file('sensu_agent_config').with_show_diff('false') }
      end

      context 'with manage_repo => false' do
        let(:pre_condition) do
          "class { 'sensu': manage_repo => false }"
        end
        it { should contain_package('sensu-go-agent').without_require }
      end

      # Test various backend values
      [
        ['ws://localhost:8081'],
        ['wss://localhost:8081'],
        ['localhost:8081'],
        ['127.0.0.1:8081'],
        ['ws://127.0.0.1:8081'],
        ['wss://127.0.0.1:8081'],
        ['test.example.com:8081'],
        ['ws://test.example.com:8081'],
        ['wss://test.example.com:8081'],
      ].each do |backends|
        context "with backends => #{backends}" do
          let(:params) { { :backends => backends } }

          # Unknown bug in rspec-puppet fails to compile windows paths
          # when they are used for file source of sensu_ssl_ca, issue with windows mocking
          if facts[:os]['family'] != 'windows'
            it { should compile.with_all_deps }
          end

          if backends[0] =~ /(ws|wss):\/\//
            backend = backends[0]
          else
            backend = "wss://#{backends[0]}"
          end

          agent_content = <<-END.gsub(/^\s+\|/, '')
            |---
            |backend-url:
            |- #{backend}
            |trusted-ca-file: #{platforms[facts[:osfamily]][:ca_path_yaml]}
          END

          it {
            should contain_file('sensu_agent_config').with({
              'ensure'  => 'file',
              'path'    => platforms[facts[:osfamily]][:agent_config_path],
              'content' => agent_content,
              'require' => 'Package[sensu-go-agent]',
              'notify'  => 'Service[sensu-agent]',
            })
          }
        end
      end
    end
  end
end

