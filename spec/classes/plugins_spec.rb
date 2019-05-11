require 'spec_helper'

describe 'sensu::plugins', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      if facts[:os]['family'] == 'windows'
        it 'should fail' do
          is_expected.to compile.and_raise_error(/is not supported/)
        end
        next
      end
      context 'with default values for all parameters' do
        it { should compile }

        it { should create_class('sensu::plugins')}
        it { should contain_class('sensu')}
        it { should contain_class('sensu::repo::community')}

        it {
          should contain_package('sensu-plugins-ruby').with({
            'ensure'  => 'installed',
            'require' => platforms[facts[:osfamily]][:plugins_package_require],
          })
        }
      end

      platforms[facts[:osfamily]][:plugins_dependencies].each do |package|
        it { should contain_package(package) }
      end

      context 'with plugins array' do
        let(:params) {{ :plugins => ['disk-checks'] }}
        it { should contain_sensu_plugin('disk-checks').with_ensure('present') }
      end

      context 'with plugins hash' do
        let(:params) {{ :plugins => {'disk-checks' => {'version' => '4.0.0'}} }}
        it {
          should contain_sensu_plugin('disk-checks').with({
            'ensure'  => 'present',
            'version' => '4.0.0',
          })
        }
      end

      context 'with extensions array' do
        let(:params) {{ :extensions => ['test'] }}
        it { should contain_sensu_plugin('test').with_ensure('present') }
        it { should contain_sensu_plugin('test').with_extension('true') }
      end

      context 'with extensions hash' do
        let(:params) {{ :extensions => {'test' => {'version' => '1.0.0'}} }}
        it {
          should contain_sensu_plugin('test').with({
            'ensure'    => 'present',
            'extension' => 'true',
            'version'   => '1.0.0',
          })
        }
      end

      context 'remove plugins' do
        let(:params) {{ :plugins => {'disk-checks' => {'ensure' => 'absent'}} }}
        it { should contain_sensu_plugin('disk-checks').with_ensure('absent') }
      end

      context 'remove extensions' do
        let(:params) {{ :extensions => {'test' => {'ensure' => 'absent'}} }}
        it { should contain_sensu_plugin('test').with_ensure('absent') }
      end

      context 'dependencies => []' do
        let(:params) {{ :dependencies => [] }}
        platforms[facts[:osfamily]][:plugins_dependencies].each do |package|
          it { should_not contain_package(package) }
        end
      end

      context 'with manage_repo => false' do
        let(:pre_condition) do
          "class { 'sensu': manage_repo => false }"
        end
        it { should_not contain_class('sensu::repo::community') }
        it { should contain_package('sensu-plugins-ruby').without_require }
      end
    end
  end
end

