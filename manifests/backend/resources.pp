# @summary Define sensu resources
# @api private
#
class sensu::backend::resources {
  include ::sensu::backend
  create_resources('sensu_ad_auth', $::sensu::backend::ad_auths)
  create_resources('sensu_asset', $::sensu::backend::assets)
  create_resources('sensu_check', $::sensu::backend::checks)
  create_resources('sensu_cluster_member', $::sensu::backend::cluster_members)
  create_resources('sensu_cluster_role_binding', $::sensu::backend::cluster_role_bindings)
  create_resources('sensu_cluster_role', $::sensu::backend::cluster_roles)
  create_resources('sensu_config', $::sensu::backend::configs)
  create_resources('sensu_entity', $::sensu::backend::entities)
  create_resources('sensu_event', $::sensu::backend::events)
  create_resources('sensu_filter', $::sensu::backend::filters)
  create_resources('sensu_handler', $::sensu::backend::handlers)
  create_resources('sensu_hook', $::sensu::backend::hooks)
  create_resources('sensu_ldap_auth', $::sensu::backend::ldap_auths)
  create_resources('sensu_mutator', $::sensu::backend::mutators)
  create_resources('sensu_namespace', $::sensu::backend::namespaces)
  create_resources('sensu_role_binding', $::sensu::backend::role_bindings)
  create_resources('sensu_role', $::sensu::backend::roles)
  create_resources('sensu_silenced', $::sensu::backend::silencing)
  create_resources('sensu_user', $::sensu::backend::users)
}
