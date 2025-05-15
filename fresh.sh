#!/data/data/com.termux/files/usr/bin/bash
set -e  # Exit if any command fails

echo "Starting Termux Fresh Setup..."

# ---- MOTD and Aliases ----
echo "SAT SAHEB JI 🙏" > "$PREFIX"/etc/motd

# Append aliases only if not already added
grep -qxF "alias ll='ls -alF'" "$PREFIX"/etc/bash.bashrc || echo "alias ll='ls -alF'" >> "$PREFIX"/etc/bash.bashrc
grep -qxF "alias upgrade='pkg update && pkg upgrade -y'" "$PREFIX"/etc/bash.bashrc || echo "alias upgrade='pkg update && pkg upgrade -y'" >> "$PREFIX"/etc/bash.bashrc
grep -qxF "alias fileserve='filebrowser -a 0.0.0.0'" "$PREFIX"/etc/bash.bashrc || echo "alias fileserve='filebrowser -a 0.0.0.0'" >> "$PREFIX"/etc/bash.bashrc

# ---- Update and Repos ----
pkg update && pkg upgrade -y
pkg install -y x11-repo tur-repo

# ---- Install Useful Tools ----
pkg install -y wget curl git unzip openssh htop file filebrowser

# ---- Setup Nerd Font ----
echo "Setting up JetBrainsMonoNerdFontPropo-Bold..."
mkdir "$PREFIX"/tmp/nerdfonts
cd "$PREFIX"/tmp/nerdfonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
unzip -q JetBrainsMono.zip
cp JetBrainsMonoNerdFontPropo-Bold.ttf ~/.termux/font.ttf
cd ~/
rm -rf "$PREFIX"/tmp/nerdfonts

# ---- Install Dev Tools ----
pkg install -y mariadb openjdk-21 maven nodejs-lts

# ---- Start MariaDB ----
echo "Starting MariaDB..."
mariadbd-safe &
# Wait until MariaDB is ready
while ! mariadb-admin ping --silent; do sleep 1; done
echo "MariaDB is up."

# ---- MariaDB User Setup ----
mariadb -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';

-- Create 'admin' user for remote access
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;

-- Create 'admin' user for local access
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF

# ---- Configure MariaDB Client Auth (no duplication) ----
MYCNF="$PREFIX/etc/my.cnf"
mkdir -p "$(dirname "$MYCNF")"
if ! grep -qFs "[client]" "$MYCNF"; then
  cat >> "$MYCNF" <<EOF
[client]
user=root
password=root
EOF
  chmod 600 "$MYCNF"
fi

# ---- Stop Mariadb ----
mariadb-admin shutdown -u root && sleep 2

echo "✅ MariaDB setup complete..."
echo "✅ Termux fresh setup finished..."
echo ""
echo ""
echo -e "\033[1;36m🔧 Alias Shortcuts Setup:\033[0m"
echo "  - ll        → ls -alF"
echo "  - upgrade   → pkg update && pkg upgrade -y"
echo "  - fileserve → Easily make the current directory accessible from any other device on the same network through Filebrowser"
echo ""
echo -e "\033[1;36m🛢️  MariaDB Setup:\033[0m"
echo "🛢️  MariaDB Setup:"
echo "  - Root user : root"
echo "    Password  : root"
echo "  - Admin user: admin"
echo "    Password  : admin"
echo ""
echo -e "\e[32m🎉 You’re almost there! Just close Termux and reopen to make the changes take effect 😃\e[0m"