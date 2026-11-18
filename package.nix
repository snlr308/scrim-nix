{
  lib,
  stdenv,
  rustPlatform,
  fetchurl,
  python3,
  curl,
  src,
  version,
}:

let
  # Must match the `v8 = "=..."` pin in upstream's scrim/Cargo.toml
  rustyV8Version = "150.4.0";

  # Prebuilt V8 static library – the v8 crate would download it at build time,
  # which the Nix sandbox forbids. Hash per platform; only x86_64-linux is tested.
  rustyV8Hashes = {
    x86_64-linux = "sha256-WGn9twcbHyHyAKl86X0gElh34PMc2ALtmd4sU/SIsGw=";
  };

  rustyV8 = fetchurl {
    url = "https://github.com/denoland/rusty_v8/releases/download/v${rustyV8Version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    hash =
      rustyV8Hashes.${stdenv.hostPlatform.system}
        or (throw "scrim: no librusty_v8 hash for ${stdenv.hostPlatform.system}");
  };
in
rustPlatform.buildRustPackage {
  pname = "scrim";
  inherit version src;

  sourceRoot = "source/scrim";

  # One hash over all vendored crates, git dependencies included. Not cargoLock:
  # upstream's Cargo.lock has debug_timer 0.1.3 twice (crates.io and Blitz git),
  # which importCargoLock cannot vendor side by side.
  cargoHash = "sha256-VRJapqDiqmo6CVBydKFM1MHp6HM98dX0Vak95i6E+2w=";

  # The v8 crate reads a local path here instead of downloading; .gz is handled
  env.RUSTY_V8_ARCHIVE = rustyV8;

  # Upstream has no test suite to speak of; the install check below is the
  # smoke test from upstream's CI (.github/workflows/build.yml)
  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    python3
    curl
  ];
  installCheckPhase = ''
    runHook preInstallCheck

    smoke=$(mktemp -d)
    cat > "$smoke/index.html" <<'HTML'
    <!doctype html><title>smoke</title>
    <p>hello scrim</p>
    <p style="display:none">hidden by inline style</p>
    <style>.gone{display:none}</style><p class="gone">hidden by stylesheet</p>
    <script>document.body.insertAdjacentHTML('beforeend','<p>from javascript</p>')</script>
    HTML
    python3 -m http.server 8231 --bind 127.0.0.1 --directory "$smoke" >/dev/null 2>&1 &
    server=$!
    for i in $(seq 1 50); do curl -sf -o /dev/null http://127.0.0.1:8231/ && break; sleep 0.2; done

    page=$($out/bin/scrim fetch http://127.0.0.1:8231/)
    kill $server
    echo "$page"
    echo "$page" | grep -q 'hello scrim'     || { echo 'visible text not read'; exit 1; }
    echo "$page" | grep -q 'from javascript' || { echo 'page JavaScript did not run'; exit 1; }
    ! echo "$page" | grep -q 'hidden'        || { echo 'hidden text leaked'; exit 1; }

    runHook postInstallCheck
  '';

  meta = {
    description = "Minimal headless browser for AI agents";
    homepage = "https://github.com/strelov1/scrim";
    license = lib.licenses.mit;
    mainProgram = "scrim";
    platforms = builtins.attrNames rustyV8Hashes;
    # librusty_v8 is a prebuilt binary from denoland/rusty_v8
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
}
