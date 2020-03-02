# @summary Add agent subscription
#
# @example
#   sensu::agent::subscription { 'mysql': }
#
# @param subscription
#   Name of the subscription to add to agent.yml, defaults to `$name`.
#
define sensu::agent::subscription (
  String $subscription = $name,
) {
  datacat_fragment { "sensu_agent_config-subscription-${name}":
    target => 'sensu_agent_config',
    data   => {
      'subscriptions' => [$subscription],
    },
  }
}
