require 'spec_helper'

describe 'sensu', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      context 'with default values for all parameters' do
        # Unknown bug in rspec-puppet fails to compile windows paths
        # when they are used for file source of sensu_ssl_ca, issue with windows mocking
        if facts[:os]['family'] != 'windows'
          it { should compile }
        end

        it { should contain_class('sensu')}
        if facts[:os]['family'] == 'windows'
          it { should_not contain_class('sensu::repo')}
        else
          it { should contain_class('sensu::repo')}
        end
        it { should contain_class('sensu::ssl') }

        it {
          should contain_file('sensu_etc_dir').with({
            'ensure'  => 'directory',
            'path'    => platforms[facts[:osfamily]][:etc_dir],
            'purge'   => true,
            'recurse' => true,
            'force'   => true,
          })
        }
      end

      context 'with use_ssl => false' do
        let(:params) { { :use_ssl => false } }
        it { should_not contain_class('sensu::ssl') }

        context 'when puppet_localcacert undefined' do
          let(:facts) { facts.merge!(puppet_localcacert: nil) }
          it { should compile }
        end
      end

      context 'when puppet_localcacert undefined' do
        let(:facts) { facts.merge!(puppet_localcacert: nil) }
        it { should compile.and_raise_error(/ssl_ca_source must be defined/) }
      end
    end
  end
end

