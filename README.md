## spinner-tool

### clone repo in

~/dev/projects

### copy alias in .bashrc

alias spinner="sh ~/dev/projects/spinner-tool/spinner-tool.sh"

### copy dxp activation key to

~/dev/projects/dxp-activation-key

### spinner-tool options:

- `spinner build`
- `spinner start`
- `spinner stop`
- `spinner rm`
- `spinner forceDeploy`
- `spinner deploy`

### spinner-tool flags:

-e environment_name | default: e5a2prd

-v release_version | default: next (latest release)

-k dxp_activation_key | default: ~/dev/projects/dxp-activation-key/.

## exemple:

`spinner -e e5a2prd -v u74 build `
