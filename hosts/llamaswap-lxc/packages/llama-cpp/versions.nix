# The only file of this package with values that change on an upgrade.
# `nix run .#update-llama-cpp` is its only writer: it replaces the whole file
# from a temporary copy, never a value at a time.
{
  version = "v1.1.0";
  # Commit behind the tag, not the tag: `llama.cpp` tags are annotated.
  rev = "171527522610996f5f0acf12334e185156ca8f44";
  hash = "sha256-0O3An2dgjy3HGF6T3ZDiEPwnv26+6B8os7htE6ocG8I=";
  npmHash = "sha256-5NCbd2NT4xSo5dCaLndj/FVorm82fUN3iv1BTwurMy4=";
  # Upstream build number of that commit, from the release's nightly-tag.txt.
  buildNumber = "b12774";
  # Directory the web UI is built from at this commit. It moves between majors
  # (`tools/ui` until v1.0.0, `ui/apps/chat` from v1.1.0); the updater checks the
  # path over the network and writes it here, so the package never has to fetch
  # the source to know it.
  uiPath = "ui/apps/chat";
}
