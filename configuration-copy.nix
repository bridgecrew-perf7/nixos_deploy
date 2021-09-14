# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

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
			postgresql jdk16_headless
# frontend requires
		nodePackages.http-server
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
	networking.firewall.allowedTCPPorts = [ 22 7000 8080 ];
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
			package = pkgs.postgresql_10;
			enableTCPIP = true;
			authentication = pkgs.lib.mkOverride 10 ''
				local all all trust
				host all all ::1/128 trust
				'';
			initialScript = pkgs.writeText "backend-initScript" ''
				CREATE ROLE nixcloud WITH LOGIN PASSWORD 'nixcloud' CREATEDB;
			CREATE DATABASE tresorier;
			GRANT ALL PRIVILEGES ON DATABASE tresorier TO nixcloud;
			'';
		};

	systemd.services.backend = {
		description = "run the application backend";
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			User = "erica";
                        WorkingDirectory = "/home/erica";
			ExecStart = "${pkgs.jdk}/bin/java -jar /home/erica/tresorier-backend-uber.jar";
			ExecStop = "/bin/kill -15 $MAINPID";
			Restart = "always";
		};
	};
}

