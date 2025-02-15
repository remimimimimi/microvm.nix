{ self, nixpkgs, system, hypervisor }:

let
  pkgs = nixpkgs.legacyPackages.${system};
  microvm = (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.microvm
      {
        networking = {
          hostName = "microvm-test";
          useDHCP = false;
        };
        microvm = {
          inherit hypervisor;
          socket = "./microvm.sock";
          crosvm.pivotRoot = "/build/empty";
        };
      }
    ];
  }).config.microvm.runner.${hypervisor};
in nixpkgs.lib.optionalAttrs microvm.canShutdown {
  # Test the shutdown command
  "${hypervisor}-shutdown-command" =
    pkgs.runCommandLocal "microvm-${hypervisor}-test-shutdown-command" {
      requiredSystemFeatures = [ "kvm" ];
    } ''
      set -m
      ${microvm}/bin/microvm-run > $out &

      sleep 10
      echo Now shutting down
      ${microvm}/bin/microvm-shutdown
    '';
}
