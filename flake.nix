{
  description = "Flutter simulator for the Salut, ca va? protocol";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems =
        fn: nixpkgs.lib.genAttrs systems (system: fn system);
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };

          androidPackages = pkgs.androidenv.composeAndroidPackages {
            platformVersions = [ "36" ];
            buildToolsVersions = [ "35.0.0" ];
            abiVersions = [ "x86_64" "arm64-v8a" "armeabi-v7a" ];
            includeNDK = true;
            ndkVersions = [ "28.2.13676358" ];
            includeCmake = true;
            cmakeVersions = [ "3.22.1" ];
          };
          androidSdk = androidPackages.androidsdk;
          androidSdkRoot = "${androidSdk}/libexec/android-sdk";
          ndkRoot = "${androidSdkRoot}/ndk/28.2.13676358";
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              flutter
              androidSdk
              jdk17
              cmake
              ninja
              pkg-config
            ];

            JAVA_HOME = pkgs.jdk17.home;
            ANDROID_HOME = androidSdkRoot;
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_NDK_HOME = ndkRoot;
            ANDROID_NDK_ROOT = ndkRoot;

            shellHook = ''
              export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
              echo "Flutter/Android dev shell ready."
              echo "Android SDK: $ANDROID_HOME"
              echo "Android NDK: $ANDROID_NDK_ROOT"
              echo "Try: flutter doctor"
            '';
          };
        }
      );
    };
}
