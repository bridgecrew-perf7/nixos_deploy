# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
#teqst

{ config, pkgs, ... }:

{
	imports =
		[ # Include the results of the hardware scan.
		./hardware-configuration.nix
		];

# Use the GRUB 2 boot loader.
	boot.loader.grub.enable = true;
	boot.loader.grub.version = 2;
# boot.loader.grub.efiSupport = true;
# boot.loader.grub.efiInstallAsRemovable = true;
# boot.loader.efi.efiSysMountPoint = "/boot/efi";
# Define on which hard drive you want to install Grub.
	boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

		networking.hostName = "kali"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

# The global useDHCP flag is deprecated, therefore explicitly set to false here.
# Per-interface useDHCP will be mandatory in the future, so this generated config
# replicates the default behaviour.
		networking.useDHCP = false;
	networking.interfaces.ens3.useDHCP = true;

# Set your time zone.
	time.timeZone = "Europe/Paris";

# List packages installed in system profile. To search, run:
# $ nix search wget
	environment.systemPackages = with pkgs; [
# adminsys requires
		wget vim git
# backend requires
			postgresql_13 jdk16_headless flyway
# frontend requires
	];

# Some programs need SUID wrappers, can be configured further or are
# started in user sessions.
	programs.mtr.enable = true;
	programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

# List services that you want to enable:

# Enable the OpenSSH daemon.
	services.openssh.enable = true;
	services.openssh.passwordAuthentication = true;

# Open ports in the firewall.
	networking.firewall.allowedTCPPorts = [ 7000 22 443 80 5432 ];
# networking.firewall.allowedUDPPorts = [ ... ];
# Or disable the firewall altogether.
# networking.firewall.enable = false;

# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.erica = {
		isNormalUser = true;
		extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
			openssh.authorizedKeys.keyFiles = [/home/erica/.ssh/authorized_keys/erica_nuwa.pub];
	};

# This value determines the NixOS release with which your system is to be
# compatible, in order to avoid breaking some software such as database
# servers. You should change this only after NixOS release notes say you
# should.
	system.stateVersion = "19.09"; # Did you read the comment?

######
# Backend setup
#####
	services.postgresql = {
		enable = true;
		package = pkgs.postgresql_13;
		enableTCPIP = true;
		authentication = pkgs.lib.mkOverride 13 ''
			local all all trust
			host all all 127.0.0.1/32 trust
			host all all ::1/128 trust
			host all all 0.0.0.0/0 md5
			'';
	};

######

	systemd.services.backend = {
		description = "run the application backend";
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			User = "erica";
			WorkingDirectory = "/home/erica";
			ExecStartPre = "/run/current-system/sw/bin/sh server/scripts/export_database.sh ${pkgs.postgresql_13} ; ${pkgs.flyway}/bin/flyway -configFiles=flyway.conf migrate";  
			ExecStart = "${pkgs.jdk}/bin/java -jar server/tresorier-backend-uber.jar";
#Restart = "always";
		};
	};


######
# HTTPS : Lets encrypt
#####

	security.acme.acceptTerms = true;
	security.acme.email = "erica@agatha-budget.fr";
	users.users.nginx.extraGroups = [ "acme" ];
	services.nginx = {
		enable = true;
		recommendedProxySettings = true;
		recommendedTlsSettings = true;
		virtualHosts = {
			"mon.agatha-budget.fr" = {
				forceSSL = true;
				enableACME = true;
				root = "/var/www/front/";
				locations."/" = {
					tryFiles = "$uri $uri/ /index.html"; 
				};
			};
			"beta.agatha-budget.fr" = {
				forceSSL = true;
				enableACME = true;
				root = "/var/www/beta/";
				locations."/" = {
					tryFiles = "$uri $uri/ /index.html"; # redirect subpages url
				};
			};
			"api.agatha-budget.fr" = {
				forceSSL = true;
				enableACME = true;
				locations."/" = {
					proxyPass = "http://localhost:7000";
				};
			};
		};
	};

######
# Cron : db save
#####
	services.cron = {
		enable = true;
		systemCronJobs = [
			"0 1 * * *	erica	/run/current-system/sw/bin/sh /home/erica/server/scripts/export_database.sh ${pkgs.postgresql_13}"
		];
	};
}

