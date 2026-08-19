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
  url "https://github.com/mihy0212/DockWindowSwitcher/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "46f639e365bcbe5ebd3fbc52ef4328878fd942c08bfacb3cd4df5a6aa0bc2781"
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
    applications = Pathname.new("/Applications")
    link = applications/"DockWindowSwitcher.app"
    target = prefix/"DockWindowSwitcher.app"

    # Homebrew keeps the bundle inside its prefix, which is awkward to reach
    # from the Accessibility file picker. A link in /Applications makes the
    # app behave like any other install. Best effort: skip it silently if the
    # directory is not writable.
    return unless applications.writable?

    if link.symlink?
      link.unlink
    elsif link.exist?
      # A real bundle is sitting there, put by install.sh or copied by hand.
      # It would shadow this install, because /Applications is what people
      # launch, so brew upgrade would keep refreshing a copy nobody runs.
      # Leave someone else's file alone and say so rather than delete it.
      opoo <<~EOS
        /Applications/DockWindowSwitcher.app already exists and is not a
        Homebrew symlink, so it was left alone. That copy is what will
        launch, not this one.

        To hand control to Homebrew:
          rm -rf /Applications/DockWindowSwitcher.app
          brew reinstall dockwindowswitcher
      EOS
      return
    end

    link.make_symlink(target)
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

      To uninstall completely, first turn off "Launch at Login" in the menu
      bar, then:
        brew uninstall dockwindowswitcher
        rm -f /Applications/DockWindowSwitcher.app

      The Accessibility entry is not removed automatically; take it out of
      the list with [-].
    EOS
  end

  test do
    assert_predicate prefix/"DockWindowSwitcher.app/Contents/MacOS/DockWindowSwitcher",
                     :executable?
  end
end
