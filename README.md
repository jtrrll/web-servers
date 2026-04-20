# web-servers

<!-- markdownlint-disable MD013 -->
![CI Status](https://img.shields.io/github/actions/workflow/status/jtrrll/web-servers/ci.yaml?branch=main&label=ci&logo=github)
![License](https://img.shields.io/github/license/jtrrll/web-servers?label=license&logo=googledocs&logoColor=white)
<!-- markdownlint-enable MD013 -->

Multipurpose web servers.
Managed via [Nix](https://nixos.org/).

## Setting Up a New Server

New servers are provisioned with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).
This installs NixOS on a server that is reachable via SSH (e.g., a fresh VPS booted into a rescue system or any Linux install with root access).

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#<hostname> root@<ip> --generate-hardware-config nixos-generate-config ./modules/hosts/by_name/<hostname>/hardware-configuration.nix
```

Disko defines the disk layout and will be applied automatically.
After installation, the server reboots into NixOS with the specified configuration.

## Updating a Server

Configuration changes are applied via `nixos-rebuild switch` over SSH.
The deploy workflow runs automatically on push to `main` and can also be triggered manually.

### Using the deploy script

```sh
nix run .#deploy
```

This presents an interactive list of deployments to choose from.
To deploy a specific deployment directly:

```sh
nix run .#deploy -- <deployment>
```

## Adding Secrets to a Server

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption derived from each server's SSH host key.

### 1. Get the server's age public key

```sh
ssh-keyscan -p 2222 <server-ip> 2>/dev/null | grep ed25519 | ssh-to-age
```

### 2. Add the key to `.sops.yaml`

```yaml
keys:
  - &<hostname> <age-public-key>
creation_rules:
  - path_regex: modules/hosts/by_name/<hostname>/secrets\.yaml$
    key_groups:
      - age:
        - *<hostname>
```

### 3. Create or edit the encrypted secrets file

```sh
sops modules/hosts/by_name/<hostname>/secrets.yaml
```

This opens an editor where you enter secrets in plaintext.
On save, sops encrypts the file with the server's public key.
Commit the encrypted file to the repository.

### 4. Reference secrets in NixOS config

```nix
sops.secrets.my_secret.owner = "service-user";
```

The decrypted secret is available at `config.sops.secrets.my_secret.path`.
