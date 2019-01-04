#!/usr/bin/env bash

#
#   bash script for setting up a virtual host in apache2 server
#

#####################################################
# Check whether a directory exists or not
# Globals:
#   None
# Arguments:
#   directory name
# Returns:
#   None
#####################################################
check_directory () {

  if [ ! -d $1 ]; then
    echo "The given directory doesn't exist!"
    echo "Please try again"
    exit
  fi
}

######################################################
# Create a directory if it doesn't exists already
# Globals:
#   domain_path
# Arguments:
#   directory name
#   flag value
# Returns:
#   None
######################################################
make_directory() {

  # Check whether the directory already exists or not
  if [ ! -d $1 ]; then

    # For virtual host domain root folder
    if [[ $1 = $domain_path ]]; then
      if [[ $2 = "y" ]]; then
        echo " "
        x="y"
      else
        echo "$1 directory doesn't exist"
        echo "Do you want to create this virtual host root folder?"

        # Get the user input
        read -p "[Press 'y' for yes and any other key for no] : " x
      fi

      # Check whether the user input is key 'y'
      if [[ $x = "y" ]]; then

        # Check whether mkdir process is successful or not
        if mkdir -p $1 ; then

          # Apply rwx permission
          chmod 755 $1
          echo " "
          echo "$1 has been created for you"
        else  # If mkdir process returned error then it means the virtual host 
          # root folder path is invalid. So throw an error message and exit
          echo " "
          echo "Error while creating $1"
          echo "Please check your directory path, its permission and try again"
          echo " "
          exit
        fi
      else
          echo " "
          echo "You have no virtual host domain root folder"
          echo "Please try again!"
          echo " "
          exit
      fi
    else # For other directories, just create it
      mkdir $1
      echo " "
      echo "$1 has been created for you"
    fi
  fi
}

# For spacing in terminal
echo " "

# Get the domain name from user
read -p "Domain name? " domain_name
echo " "

# For default configuration
# -y as second argument
if [[ $1 = "-y" ]]; then
  echo "You are using default configuration now"
  domain_path="/var/www/html/$domain_name"
  x='y'
  make_directory $domain_path $x
  apache_path="/etc/apache2/sites-available"
else

  # Get the root folder path from user
  read -p "Enter virtual host root folder full path: " domain_path

  # Check whether virtual host domain path exists or not
  # If not, create directory
  make_directory $domain_path
  echo " "

  # Check whether the user wants to use the default /etc/apache2/sites-available folder path
  echo "Do you want to use the default /etc/apache2/sites-available path for configuring virtual host configuration file?"
  read -p "[Press 'y' for yes and any other key for no] : " x

  # Set the apache folder path to default
  if [[ $x = "y" ]]; then
    apache_path="/etc/apache2/sites-available"
  else # Get the apache folder path from user
    read -p "Enter your path for configuring the virtual host configuration file : " apache_path

    # Check whether apache path exists or not
    check_directory $apache_path
  fi
  echo " "
fi

# Check whether the domain already exists in that root folder
if [ -e $apache_path/$domain_name.conf ]; then
  echo "----------------------------"
  echo "This domain already exists!"
  echo "Please try another one"
  echo "----------------------------"
  exit
fi


# Log folder needs to be in parallel with virtual host root directory
# For that purpose go one directory up from the root folder
# and set $domain_name_log folder there
domain_log_path=${domain_path%/*}"/doc"
echo " "
echo "$domain_log_path folder will be created for error log and access log files"
make_directory $domain_log_path

# Add domain name into hosts file
sudo echo "127.0.0.1	$domain_name" >> /etc/hosts
echo " "

# write the configuration file and place it in apache folder path
sudo echo "
  <VirtualHost *:80>
    ServerName $domain_name
    ServerAdmin webmaster@localhost
    DocumentRoot "$domain_path"/public
    <Directory "$domain_path"/public>
      Options Indexes FollowSymLinks
      AllowOverride All
      Require all granted
    </Directory>
      ErrorLog "$domain_log_path/$domain_name"_error.log
      CustomLog "$domain_log_path/$domain_name"_access.log combined
  </VirtualHost>" > $apache_path/$domain_name.conf

# Change directory to apache folder path
cd $apache_path

# Enable the configuration file
sudo a2ensite $domain_name.conf

# Restart the apache server
sudo service apache2 restart

# Print success message
echo " "
echo "----------------------------------------------------------------"
echo "Congratulation krishna. You have successfully created the domain : http://$domain_name"
echo "Virtual host root folder : $domain_path"
echo "Error & access logs folder (doc folder) : $domain_log_path"
echo "----------------------------------------------------------------"
exit
