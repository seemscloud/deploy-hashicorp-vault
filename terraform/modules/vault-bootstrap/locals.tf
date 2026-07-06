locals {
  roots_catalog           = yamldecode(file(var.roots_file))
  roles_catalog           = yamldecode(file(var.roles_file))
  example_secrets_catalog = yamldecode(file(var.example_secrets_file))
  workloads_catalog       = yamldecode(file(var.workloads_file))

  kv_mounts = {
    for mount_name, mount in try(local.roots_catalog.mounts, {}) : mount_name => {
      name               = mount_name
      path               = trim(tostring(try(mount.path, mount_name)), "/")
      description        = tostring(try(mount.description, "KV v2 mount ${mount_name}."))
      listing_visibility = tostring(try(mount.listing_visibility, "hidden"))
    }
  }

  root_path_level_1 = flatten([
    for mount_name, root in try(local.roots_catalog.roots, {}) : [
      for segment, node in try(root.paths, {}) : {
        mount_name = mount_name
        path       = trim(tostring(segment), "/")
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_level_2 = flatten([
    for parent in local.root_path_level_1 : [
      for segment, node in try(jsondecode(parent.node_json), {}) : {
        mount_name = parent.mount_name
        path       = "${parent.path}/${trim(tostring(segment), "/")}"
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_level_3 = flatten([
    for parent in local.root_path_level_2 : [
      for segment, node in try(jsondecode(parent.node_json), {}) : {
        mount_name = parent.mount_name
        path       = "${parent.path}/${trim(tostring(segment), "/")}"
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_level_4 = flatten([
    for parent in local.root_path_level_3 : [
      for segment, node in try(jsondecode(parent.node_json), {}) : {
        mount_name = parent.mount_name
        path       = "${parent.path}/${trim(tostring(segment), "/")}"
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_level_5 = flatten([
    for parent in local.root_path_level_4 : [
      for segment, node in try(jsondecode(parent.node_json), {}) : {
        mount_name = parent.mount_name
        path       = "${parent.path}/${trim(tostring(segment), "/")}"
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_level_6 = flatten([
    for parent in local.root_path_level_5 : [
      for segment, node in try(jsondecode(parent.node_json), {}) : {
        mount_name = parent.mount_name
        path       = "${parent.path}/${trim(tostring(segment), "/")}"
        node_json  = jsonencode(try(node, {}))
      }
    ]
  ])

  root_path_entries = concat(
    local.root_path_level_1,
    local.root_path_level_2,
    local.root_path_level_3,
    local.root_path_level_4,
    local.root_path_level_5,
    local.root_path_level_6,
  )

  root_paths = {
    for entry in local.root_path_entries : "${entry.mount_name}/${entry.path}" => {
      mount_name = entry.mount_name
      mount_path = local.kv_mounts[entry.mount_name].path
      path       = entry.path
      full_path  = "${local.kv_mounts[entry.mount_name].path}/${entry.path}"
    }
    if contains(keys(local.kv_mounts), entry.mount_name) && entry.path != ""
  }

  roles = {
    for role_slug, role in try(local.roles_catalog.roles, {}) : role_slug => {
      slug         = role_slug
      display_name = try(tostring(role.display_name), role_slug)
      username     = try(tostring(role.username), role_slug)
      auth_groups = try({
        for auth_source, group in role.auth_groups :
        tostring(auth_source) => {
          name    = tostring(group.name)
          aliases = distinct(compact([for alias in tolist(group.aliases) : tostring(alias)]))
        }
      }, {})
      token_role_name   = try(tostring(role.token_role_name), role_slug)
      token_policy_name = try(tostring(role.token_policy_name), "${role_slug}-secrets")
    }
  }

  role_grant_entries = flatten([
    for role_slug, role in try(local.roles_catalog.roles, {}) : [
      for grant_path, grant in try(role.grants, {}) : {
        key           = "${role_slug}/${trim(tostring(try(grant.path, grant_path)), "/")}"
        role_slug     = role_slug
        raw_path      = trim(tostring(try(grant.path, grant_path)), "/")
        access        = lower(tostring(try(grant.access, tostring(grant), "write")))
      }
      if length(split("/", trim(tostring(try(grant.path, grant_path)), "/"))) > 1
    ]
  ])

  role_grants = {
    for grant in local.role_grant_entries : grant.key => {
      key           = grant.key
      role_slug     = grant.role_slug
      access        = grant.access
      mount_path    = split("/", grant.raw_path)[0]
      path          = join("/", slice(split("/", grant.raw_path), 1, length(split("/", grant.raw_path))))
      raw_path      = grant.raw_path
    }
  }

  role_write_secret_path_maps = {
    for role_slug in keys(local.roles) : role_slug => {
      for key, grant in local.role_grants :
      "${grant.mount_path}/${grant.path}" => {
        mount_path = grant.mount_path
        path       = grant.path
      }
      if grant.role_slug == role_slug && grant.access != "read"
    }
  }

  role_read_secret_path_maps = {
    for role_slug in keys(local.roles) : role_slug => {
      for key, grant in local.role_grants :
      "${grant.mount_path}/${grant.path}" => {
        mount_path = grant.mount_path
        path       = grant.path
      }
      if grant.role_slug == role_slug && grant.access == "read" && !contains(keys(local.role_write_secret_path_maps[role_slug]), "${grant.mount_path}/${grant.path}")
    }
  }

  role_metadata_list_path_maps = {
    for role_slug in keys(local.roles) : role_slug => {
      for key, items in {
        for item in flatten([
          for grant in values(local.role_grants) : [
            for depth in range(0, length(split("/", grant.path))) : {
              key        = "${grant.mount_path}/${depth == 0 ? "" : join("/", slice(split("/", grant.path), 0, depth))}"
              mount_path = grant.mount_path
              path       = depth == 0 ? "" : join("/", slice(split("/", grant.path), 0, depth))
            }
          ] if grant.role_slug == role_slug
        ]) : item.key => item...
        } : key => {
        mount_path = items[0].mount_path
        path       = items[0].path
      }
    }
  }

  role_policy_bindings = {
    for role_slug, role in local.roles : role_slug => {
      team_slug           = role_slug
      policy_name         = role.token_policy_name
      metadata_list_paths = values(local.role_metadata_list_path_maps[role_slug])
      read_secret_paths   = values(local.role_read_secret_path_maps[role_slug])
      write_secret_paths  = values(local.role_write_secret_path_maps[role_slug])
    }
  }

  example_secret_entries = concat(
    [
      for secret_path, secret in try(local.example_secrets_catalog.example_secrets, {}) : {
        raw_path = trim(tostring(try(secret.path, secret_path)), "/")
        data     = secret.data
      }
      if can(secret.data) && length(split("/", trim(tostring(try(secret.path, secret_path)), "/"))) > 1
    ],
    flatten([
      for service_path, service in try(local.example_secrets_catalog.example_secrets, {}) : [
        for entry in try(service.paths, []) : {
          raw_path = "${trim(tostring(try(service.path, service_path)), "/")}/${trim(tostring(entry.path), "/")}"
          data     = entry.data
        }
        if trim(tostring(entry.path), "/") != ""
      ]
      if length(split("/", trim(tostring(try(service.path, service_path)), "/"))) > 1
    ])
  )

  example_secrets = {
    for secret in local.example_secret_entries : secret.raw_path => {
      mount = split("/", secret.raw_path)[0]
      name  = join("/", slice(split("/", secret.raw_path), 1, length(split("/", secret.raw_path))))
      data  = secret.data
    }
  }

  kubernetes_auth_backends = {
    for auth_key, auth in try(local.workloads_catalog.kubernetes_auth, {}) : auth_key => {
      mount                  = trim(tostring(try(auth.mount, auth_key)), "/")
      display_name           = try(tostring(auth.display_name), auth_key)
      description            = tostring(try(auth.description, "Kubernetes auth ${auth_key}."))
      kubernetes_host        = tostring(auth.kubernetes_host)
      disable_local_ca_jwt   = tobool(try(auth.disable_local_ca_jwt, false))
      disable_iss_validation = tobool(try(auth.disable_iss_validation, true))
      issuer                 = try(tostring(auth.issuer), null)
      kubernetes_ca_cert     = try(tostring(auth.kubernetes_ca_cert), null)
      token_reviewer_jwt     = try(tostring(auth.token_reviewer_jwt), null)
    }
  }

  workload_grant_entries = flatten([
    for workload_key, workload in try(local.workloads_catalog.workloads, {}) : [
      for grant_path, grant in try(workload.grants, {}) : {
        key          = "${workload_key}/${trim(tostring(try(grant.path, grant_path)), "/")}"
        workload_key = workload_key
        raw_path     = trim(tostring(try(grant.path, grant_path)), "/")
      }
      if length(split("/", trim(tostring(try(grant.path, grant_path)), "/"))) > 1
    ]
  ])

  workload_read_secret_path_maps = {
    for workload_key, workload in try(local.workloads_catalog.workloads, {}) : workload_key => {
      for grant in local.workload_grant_entries :
      grant.raw_path => {
        mount_path = split("/", grant.raw_path)[0]
        path       = join("/", slice(split("/", grant.raw_path), 1, length(split("/", grant.raw_path))))
      }
      if grant.workload_key == workload_key
    }
  }

  workloads = {
    for workload_key, workload in try(local.workloads_catalog.workloads, {}) : workload_key => {
      auth_key              = tostring(workload.auth)
      display_name          = try(tostring(workload.display_name), workload_key)
      role_name             = try(tostring(workload.role_name), workload_key)
      policy_name           = try(tostring(workload.policy_name), "${workload_key}-secrets")
      namespaces            = distinct(compact(try(tolist(workload.namespaces), [tostring(workload.namespace)])))
      service_accounts      = distinct(compact(try(tolist(workload.service_accounts), [tostring(workload.service_account)])))
      token_ttl_seconds     = tonumber(try(workload.token_ttl_seconds, 3600))
      token_max_ttl_seconds = tonumber(try(workload.token_max_ttl_seconds, 14400))
      read_secret_paths     = values(local.workload_read_secret_path_maps[workload_key])
    }
    if contains(keys(local.kubernetes_auth_backends), tostring(workload.auth))
  }
}
