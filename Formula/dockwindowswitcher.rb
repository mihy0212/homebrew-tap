# Lives in the tap repository, not in the project repository:
#
#   github.com/mihy0212/homebrew-tap  ->  Formula/dockwindowswitcher.rb
#
# This copy is the source of truth. Publish/update-formula.sh stamps a new
# version and checksum into it; copy the result into the tap and push.

# Builds DockWindowSwitcher from source on the user's machine.
class Dockwindowswitcher < Formula
  desc "Raise only an app's most recent window when its Dock icon is clicked"
  homepage "https://github.com/mihy0212/DockWindowSwitcher"
  url "https://github.com/mihy0212/DockWindowSwitcher/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "4a24d82086bd2a7b47aa2a74946d06c0a8e6552c57dc21b34b5acfea9c95a7f9"
  license "MIT"
  head "https://github.com/mihy0212/DockWindowSwitcher.git", branch: "main"

  depends_on macos: :ventura

  def install
    # build.sh writes the bundle next to itself unless told otherwise.
    ENV["APP_DIR"] = buildpath.to_s
    system "./build.sh"
    prefix.install "DockWindowSwitcher.app"
  end

  def post_install
    # Homebrew keeps the bundle inside its prefix, which is awkward to reach
    # from the Accessibility file picker. A link in /Applications makes the
    # app behave like any other install. Best effort: skip it silently if the
    # directory is not writable.
    link = Pathname.new("/Applications/DockWindowSwitcher.app")
    target = prefix/"DockWindowSwitcher.app"

    return unless Pathname.new("/Applications").writable?

    link.unlink if link.symlink?
    link.make_symlink(target) unless link.exist?
  end

  def caveats
    <<~EOS
      Launch it with:
        open /Applications/DockWindowSwitcher.app

      Then grant Accessibility permission:
        System Settings > Privacy & Security > Accessibility

      macOS does not let one app read or focus another app's windows without
      it, and the Dock click cannot be intercepted without it either.

      Upgrading rebuilds the app on this machine, which changes its ad-hoc
      code signature. macOS ties the permission to that signature, so after
      an upgrade remove DockWindowSwitcher from the Accessibility list with
      [-] and add it again with [+].

      Uninstalling leaves the /Applications symlink behind:
        rm /Applications/DockWindowSwitcher.app
    EOS
  end

  test do
    assert_predicate prefix/"DockWindowSwitcher.app/Contents/MacOS/DockWindowSwitcher",
                     :executable?
  end
end
