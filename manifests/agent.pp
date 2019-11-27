# @summary Manage Sensu agent
#
# Class to manage the Sensu agent.
#
# @example
#   class { 'sensu::agent':
#     backends    => ['sensu-backend.example.com:8081'],
#     config_hash => {
#       'subscriptions => ['linux', 'apache-servers'],
#     },
#   }
#
# @param version
#   Version of sensu agent to install.  Defaults to `installed` to support
#   Windows MSI packaging and to avoid surprising upgrades.
# @param package_source
#   Source of package for installing Windows.
#   Paths with http:// or https:// will be downloaded
#   Paths with puppet:// or absolute filesystem paths will also be installed.
# @param package_download_path
#   Where to download the MSI for Windows. Defaults to `C:\`.
#   This parameter only used when `package_source` is an URL or when it's a puppet source (`puppet://`).
# @param package_name
#   Name of Sensu agent package.
# @param service_name
#   Name of the Sensu agent service.
# @param service_ensure
#   Sensu agent service ensure value.
# @param service_enable
#   Sensu agent service enable value.
# @param config_hash
#   Sensu agent configuration hash used to define agent.yml.
# @param backends
#   Array of sensu backends to pass to `backend-url` config option.
#   Default is `["${::sensu::api_host}:8081"]`
#   The protocol prefix of `ws://` or `wss://` are optional and will be determined
#   based on `sensu::use_ssl` parameter by default.
#   Passing `backend-url` as part of `config_hash` takes precedence over this parameter.
# @param show_diff
#   Sets show_diff parameter for agent.yml configuration file
# @param log_file
#   Path to agent log file, only for Windows.
#   Defaults to `C:\ProgramData\sensu\log\sensu-agent.log`
#
class sensu::agent (
  Optional[String] $version = undef,
  Optional[String[1]] $package_source = undef,
  Optional[Stdlib::Absolutepath] $package_download_path = undef,
  String $package_name = 'sensu-go-agent',
  String $service_name = 'sensu-agent',
  String $service_ensure = 'running',
  Boolean $service_enable = true,
  Hash $config_hash = {},
  Optional[Array[Sensu::Backend_URL]] $backends = undef,
  Boolean $show_diff = true,
  Optional[Stdlib::Absolutepath] $log_file = undef,
) {

  include ::sensu

  $etc_dir = $::sensu::etc_dir
  $ssl_dir = $::sensu::ssl_dir
  $use_ssl = $::sensu::use_ssl
  $_version = pick($version, $::sensu::version)
  $_backends = pick($backends, ["${::sensu::api_host}:8081"])

  if $use_ssl {
    $backend_protocol = 'wss'
    $ssl_config = {
      'trusted-ca-file' => $::sensu::trusted_ca_file_path,
    }
    $service_subscribe = Class['::sensu::ssl']
  } else {
    $backend_protocol = 'ws'
    $ssl_config = {}
    $service_subscribe = undef
  }
  $backend_urls = $_backends.map |$backend| {
    if 'ws://' in $backend or 'wss://' in $backend {
      $backend
    } else {
      "${backend_protocol}://${backend}"
    }
  }
  $default_config = {
    'backend-url' => $backend_urls,
  }
  $config = $default_config + $ssl_config + $config_hash

  if $facts['os']['family'] == 'windows' {
    $sensu_agent_exe = "C:\\Program Files\\sensu\\sensu-agent\\bin\\sensu-agent.exe"
    exec { 'install-agent-service':
      command => "C:\\windows\\system32\\cmd.exe /c \"\"${sensu_agent_exe}\" service install --config-file \"${::sensu::agent_config_path}\" --log-file \"${log_file}\"\"", # lint:ignore:140chars
      unless  => "C:\\windows\\system32\\sc.exe query SensuAgent",
      before  => Service['sensu-agent'],
      require => [
        Package['sensu-go-agent'],
        File['sensu_agent_config'],
      ],
    }
    if $package_source and ($package_source =~ Stdlib::HTTPSUrl or $package_source =~ Stdlib::HTTPUrl) {
      $package_provider = undef
      $package_source_basename = basename($package_source)
      $_package_source = "${package_download_path}\\${package_source_basename}"
      archive { 'sensu-go-agent.msi':
        source  => $package_source,
        path    => $_package_source,
        extract => false,
        cleanup => false,
        before  => Package['sensu-go-agent'],
      }
    } elsif $package_source and $package_source =~ /^puppet:/ {
      $package_provider = undef
      $package_source_basename = basename($package_source)
      $_package_source = "${package_download_path}\\${package_source_basename}"
      file { 'sensu-go-agent.msi':
        ensure => 'file',
        path   => $_package_source,
        source => $package_source,
        before => Package['sensu-go-agent'],
      }
    } elsif $package_source {
        $package_provider = undef
        $_package_source = $package_source
    } else {
      include ::chocolatey
      $package_provider = 'chocolatey'
      $_package_source = $package_source
    }
  } else {
    $package_provider = undef
    $_package_source = undef
  }

  package { 'sensu-go-agent':
    ensure   => $_version,
    name     => $package_name,
    source   => $_package_source,
    provider => $package_provider,
    before   => File['sensu_etc_dir'],
    require  => $::sensu::package_require,
  }

  file { 'sensu_agent_config':
    ensure    => 'file',
    path      => $::sensu::agent_config_path,
    content   => to_yaml($config),
    owner     => $::sensu::sensu_user,
    group     => $::sensu::sensu_group,
    mode      => $::sensu::file_mode,
    show_diff => $show_diff,
    require   => Package['sensu-go-agent'],
    notify    => Service['sensu-agent'],
  }

  service { 'sensu-agent':
    ensure    => $service_ensure,
    enable    => $service_enable,
    name      => $service_name,
    subscribe => $service_subscribe,
  }
}
