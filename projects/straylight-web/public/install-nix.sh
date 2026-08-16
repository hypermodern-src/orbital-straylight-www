#!/bin/sh
# Straylight Nix Installer
# curl -sSfL https://straylight.dev/install-nix.sh | sh
#
# Installs Nix with straylight defaults (flakes, registry, cachix).

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Straylight // Nix Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Install Nix via Determinate Systems installer
if ! command -v nix >/dev/null 2>&1; then
	echo ":: Installing Nix..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

	# Source nix for this session
	if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
		. '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
	fi
else
	echo ":: Nix already installed: $(nix --version)"
fi

# Configure straylight defaults
echo ":: Configuring straylight defaults..."
mkdir -p ~/.config/nix

# Enable flakes if not already
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
	echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
fi

# Add straylight flake registry
nix registry add straylight github:straylight-software/aleph 2>/dev/null || true

# Add cachix substituter
if ! grep -q "weyl-ai.cachix.org" ~/.config/nix/nix.conf 2>/dev/null; then
	echo "extra-substituters = https://weyl-ai.cachix.org" >>~/.config/nix/nix.conf
	echo "extra-trusted-public-keys = weyl-ai.cachix.org-1:NWy8MiNiSLvkompKqN5+WZ8rDWiMXPrkVQO2c4FqXWQ=" >>~/.config/nix/nix.conf
fi

echo ""
echo ":: Installation complete!"
echo ""
echo "Usage:"
echo "  nix run straylight#<package>"
echo "  nix develop straylight"
echo ""
