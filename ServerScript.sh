#!/bin/bash

# Function to check and reinstall packages
check_and_reinstall_packages() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package"; then
            echo "$package is installed. Removing..."
            sudo apt remove --purge -y "$package"
        fi
        echo "Installing $package..."
        sudo apt install -y "$package"
    done
}

# Function to display the menu
show_menu() {
    echo "Option List"
    echo "1. Upgrade System Packages"
    echo "2. Display IP Address and Hostname"
    echo "3. Install/Reinstall Apache Web Server"
    echo "4. Install/Reinstall LDAP Server and Utils"
    echo "5. Check Server Status"
    echo "6. Configure Apache2"
    echo "7. Install/Reinstall LDAP Account Manager"
    echo "8. Configure LDAP and Apache"
    echo "100. Exit"
}

# Function to handle user selection
handle_selection() {
    case "$1" in
        1)
            echo "Updating system packages..."
            sudo apt update && sudo apt upgrade -y
            echo "System packages upgraded."
            ;;
        2)
            IpAddress=$(hostname -i)
            echo "IP Address: $IpAddress"
            NOM=$(hostname -f)
            echo "Fully Qualified Domain Name: $NOM"
            ;;
        3)
            echo "Installing/Reinstalling Apache Web Server..."
            check_and_reinstall_packages apache2 php php-cgi libapache2-mod-php php-mbstring php-common php-pear
            echo "Apache Web Server installed/reinstalled."
            ;;
        4)
            echo "Installing/Reinstalling LDAP Server and Utils..."
            # Create pre-seed file
            echo "Setting up LDAP pre-seed..."
            sudo bash -c 'cat << EOF > /tmp/ldap_preseed.cfg
slapd slapd/no_configuration boolean false
slapd slapd/domain string core-auth.zoo.local
slapd slapd/password1 password admin
slapd slapd/password2 password admin
slapd shared/organization string zaboomboom
EOF'

            # Set pre-seed selections
            sudo debconf-set-selections < /tmp/ldap_preseed.cfg
            
            check_and_reinstall_packages slapd ldap-utils
            echo "LDAP Server and Utils installed/reinstalled."
            ;;
        5)
            echo "Checking Server Status..."
            sudo systemctl status slapd 
            ;;
        6)
            echo "Configuring Apache2..."
            sudo a2enconf php*-cgi
            sudo systemctl restart apache2
            sudo systemctl enable apache2
            echo "Apache2 configured."
            ;;
        7) 
            echo "Installing/Reinstalling LDAP Account Manager..."
            check_and_reinstall_packages ldap-account-manager
            echo "LDAP Account Manager installed/reinstalled."
            ;;
        8) 
            echo "Configuring LDAP and Apache..."
            IP_ADDRESS="172.17.123.249"  # Change this to your desired IP address
            DOMAIN="core-auth.zoo.local"

            # Check if the entry already exists
            if ! grep -q "$DOMAIN" /etc/hosts; then
                echo "Adding $DOMAIN to /etc/hosts"
                echo "$IP_ADDRESS $DOMAIN" | sudo tee -a /etc/hosts > /dev/null
            else
                echo "$DOMAIN already exists in /etc/hosts"
            fi

            # Enable Apache modules
            sudo a2enmod rewrite
            sudo a2enmod headers
            sudo systemctl restart apache2

            echo "Run 'sudo nano /etc/apache2/sites-available/lam.conf' to configure the site."
            echo "Check for server name: $DOMAIN"
            echo "Configured IP: $IP_ADDRESS"
            ;;

        100)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option selected. Please try again."
            ;;
    esac
}

# Main loop
while true; do
    show_menu
    read -p "Please select an option: " option
    handle_selection "$option"
    echo ""
done

<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/lam

    <Directory /var/www/lam>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/lam_error.log
    CustomLog ${APACHE_LOG_DIR}/lam_access.log combined
</VirtualHost>
