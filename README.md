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

The flags are used only with the **build** option.

`-e environment_name`
default: e5a2prd
Ex:
`spinner -e e5a2prd build`
`spinner -e e5a2prd stop`

`-v release_version`
default: next (latest release)
Ex:
`spinner -v u64 build`

`-k dxp_activation_key`
default: ~/dev/projects/dxp-activation-key/.
Ex:
`spinner -k ~/Downloads/activation-key-7.4.xml build`

## exemple:

`spinner -e e5a2prd -v u74 build `
