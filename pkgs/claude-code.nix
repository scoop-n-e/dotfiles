# 自前derivation(主方式)。Anthropic CDNから単一ネイティブバイナリを直接fetchurlで取得する。
# npmレジストリを経由しないことで取得元をAnthropic直接のみに固定できる(選定理由は計画書§3参照)。
# 実装パターンはsadjow/claude-code-nix(2026-07-20時点でのversion/sha256を確認して転記済み)を
# 参考にした自前実装であり、flake入力として依存はしていない。
#
# 更新手順: version・nativeHashesを書き換える定型作業(数分/回)。
# 最新版とsha256は https://github.com/sadjow/claude-code-nix/blob/main/package.nix で確認できる。
{ lib
, stdenv
, fetchurl
, makeBinaryWrapper
, autoPatchelfHook
, procps
, ripgrep
, bubblewrap
, socat
}:

let
  version = "2.1.215";

  # 本機はx86_64-linux固定のため単一プラットフォームのみ扱う。
  sha256 = "1zp7pmjbd49pz1v881xhk5l6872i9qyxk7d0nry1iakhyfmgzvy1";

  nativeBinary = fetchurl {
    urls = [
      "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude"
      "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/linux-x64/claude"
    ];
    inherit sha256;
  };
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  dontUnpack = true;
  dontStrip = true; # embedded Bunトレーラーを保持するため

  nativeBuildInputs = [ makeBinaryWrapper autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 ${nativeBinary} $out/bin/.claude-unwrapped

    makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
      --inherit-argv0 \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${lib.makeBinPath [ procps ripgrep bubblewrap socat ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI coding assistant in your terminal";
    homepage = "https://www.anthropic.com/claude-code";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
