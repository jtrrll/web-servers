{ config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.caddy_basic_auth_hash = { };
    templates."caddy.env" = {
      owner = "caddy";
      content = "CADDY_BASIC_AUTH_HASH=${config.sops.placeholder.caddy_basic_auth_hash}";
    };
  };

  boot.loader.grub = {
    enable = true;
    configurationLimit = 2;
  };

  adminUser.enable = true;

  services = {
    caddy = {
      enable = true;
      openFirewall = true;
      environmentFile = config.sops.templates."caddy.env".path;

      virtualHosts = {
        "www.jtrrll.com".extraConfig = ''
          reverse_proxy localhost:8080
        '';

        "jtrrll.com".extraConfig = ''
          redir https://www.jtrrll.com{uri}
        '';

        "admin.jtrrll.com".extraConfig = ''
          basic_auth {
            admin {$CADDY_BASIC_AUTH_HASH}
          }
          reverse_proxy localhost:5678
        '';
      };
    };

    fail2ban = {
      enable = true;
      maxretry = 3;
    };

    openssh = {
      enable = true;
      ports = [ 2222 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    glance = {
      enable = true;
      settings = {
        server = {
          port = 5678;
          proxied = true;
        };
        pages = [
          {
            name = "Home";
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                        name = config.networking.hostName;
                      }
                    ];
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Services";
                    sites = [
                      {
                        title = "Portfolio";
                        url = "https://www.jtrrll.com";
                        icon = "si:globe";
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };

    portfolio.enable = true;
  };

  system.stateVersion = "25.11";
}
