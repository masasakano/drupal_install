#!/bin/sh
 
## Default values
dryrun="FALSE"
forcedir="FALSE"
defDir=""
defCoreVer=""
adminUsername="admin"
adminEmail="admin@example.com"
dbHost="localhost"	# Change it here, if necessary!
dbName="drupalmysql"
siteName="Drupal Example"
siteSlogan="Get the example right!"
siteLocale="en"

### Handle the command-line arguments
usage="USAGE: sh $0 [-h] [Options] -d Directory < STDIN(DB-Password)\n
 1-line is (silently) read from STDIN: MySql database password.\n
 Options:\n
  -h: Help (and exit)\n
  -n: Dryrun\n
  -f: Force - mkdir if the directory does not exist or destroy if contents exist\n
  -d: (Mandatory) Installing directory\n
    NOTE: Directory should exist and be empty (unless -f option is specified)!\n
  -c: Core-version (a single number, eg 7, or 'drupal-8.0'. Def: up to drush)\n
  -u,-m: Username(=Password. Def=admin), mail address of Administrator\n
  -q: Database name(=Database-user) (Def: drupalmysql)\n
  -t: Site Title  (Def: 'Drupal Example')\n
  -s: Site Slogan (Def: 'Get the example right!')\n
  -l: Site Locale (Def: en)"

while getopts hnfd:c:u:m:q:t:s:l: OPT
do
  case $OPT in
    "h" ) echo $usage;     exit 0 ;;
    "n" ) dryrun="TRUE" ;;
    "f" ) forcedir="TRUE" ;;
    "d" ) OPTS_D="TRUE" ; defDir="$OPTARG" ;;
    "c" ) OPTS_C="TRUE" ; defCoreVer="$OPTARG" ;;
    "u" ) OPTS_U="TRUE" ; adminUsername="$OPTARG" ;;
    "m" ) OPTS_M="TRUE" ; adminEmail="$OPTARG" ;;
    "q" ) OPTS_Q="TRUE" ; dbName="$OPTARG" ;;
    "t" ) OPTS_T="TRUE" ; siteName="$OPTARG" ;;
    "s" ) OPTS_S="TRUE" ; siteSlogan="$OPTARG" ;;
    "l" ) OPTS_L="TRUE" ; siteLocale="$OPTARG" ;;
    "?" ) echo $usage;     exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`      # To cut the option parts.

if [ "$#" -ne 0 ]; then
  echo "ERROR: No argument (but options) is accepted." >&2
  echo $usage;     exit 1
elif [ "X$defDir" = 'X' ]; then
  echo "ERROR: [-d Directory] is mandatory.  (-h to dispaly help.)" >&2
  exit 1
fi

### Checking the installing directory

if [ ! -d $defDir ]; then
  if [ $forcedir = "TRUE" ]; then
    echo "WARNING: Directory ($defDir) does not exist.  Creating..." >&2
    com="mkdir -p '$defDir'"
    echo "% $com"
    eval $com
    exitstatus=$?
    if [ "$exitstatus" -ne 0 ]; then
      echo "FATAL: Failed to mkdir ($defDir)." >&2
      exit $exitstatus
    fi
  else
    echo "FATAL: ($defDir) does not exist or is not directory.  May use -f option?  Stop." >&2
    exit 1
  fi
fi
 
### Adjusting the Drupal version

if [ "X$defCoreVer" = "X" ]; then
  # Do nothing (no version for Drupal-core is specified)
  :
elif [ "X"`echo $defCoreVer | sed 's/[0-9 ]*//'` = "X" ]; then
  # Version is specified as a number.
    defCoreVer="drupal-$defCoreVer.x"
else
  # Do nothing (Full Drupal version is specified, like drupal-8.0)
  :
fi

### Determine the directories
cwd=`pwd`
com="cd $defDir"
# echo "% $com"
eval $com
exitstatus=$?
if [ "$exitstatus" -ne 0 ]; then
  echo "FATAL: Failed to chdir to ($defDir)." >&2
  exit $exitstatus
fi
 
allDir=`pwd`
num_allDirContents=`ls | wc -l` 
httpDir=`dirname  $allDir`
rootDir=`basename $allDir`
cd $cwd

if [ "$allDir" = "$cwd" ]; then
  echo "FATAL: Current directory can not be the installing directory, as it would be deleted and recreated.  Stop." >&2
  exit 1
elif [ $num_allDirContents -ne 0 ]; then
  if [ $forcedir = "TRUE" ]; then
    echo "WARNING: Directory ($allDir) is not empty.  Overwritten." >&2
  elif [ $dryrun = "TRUE" ]; then
    echo "WARNING: Directory ($allDir) is not empty.  Specify -f if you want to destroy and recreate the directory.  (Continued, as a dry-run.)" >&2
  else
    echo "FATAL: Directory ($allDir) is not empty.  Specify -f if you want to destroy and recreate the directory.  Stop." >&2
    exit 1
  fi
fi


### Read Database password (silent mode)
read -s -p 'Database Password: ' dbPassword
dbUser=$dbName	# Database user name is the same as the database name.
adminPassword=$adminUsername	# Admin password is the same as the user name.

### Check Database connection
echo "USE $dbName;" | mysql -u $dbUser -p$dbPassword > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  echo "WARNING: Failed to read the database." >&2
fi

### Print the summary message.
echo "// Now, installing Drupal:
 Directory: $defDir
 Site-Name: $siteName
 Site-Slogan: $siteSlogan
 Site-Locale: $siteLocale
 Admin-Username: $adminUsername
 Admin-Email: $adminEmail
 Database-Host: $dbHost
 Database-Name: $dbName
 Database-User: $dbUser"


##########################################################
 
## Initialisation
midexitstatus="SUCCESS"

# Download Core
##########################################################
com="drush dl -y --destination=$httpDir --drupal-project-rename=$rootDir $defCoreVer";
echo "% $com"
[ $dryrun = "TRUE" ] || $com
exitstatus=$?
if [ $dryrun != "TRUE" -a "$exitstatus" -ne 0 ]; then
  echo "Failed." >&2
  exit $exitstatus
fi

com="cd $httpDir/$rootDir"
echo "% $com"
eval $com
exitstatus=$?
if [ "$exitstatus" -ne 0 ]; then
  echo "FATAL: Failed to chdir to ($httpDir/$rootDir)." >&2
  exit $exitstatus
fi
 
# Install core
##########################################################
com="drush site-install -y standard --account-mail=$adminEmail --account-name=$adminUsername --account-pass='$adminPassword' --site-name='$siteName' --site-mail=$adminEmail --locale=$siteLocale --db-url='mysql://$dbUser:@@@@@$dbHost/$dbName'";
# dbpassquoted=`echo "$dbPassword" | sed -e 's/\\/\\\\/g'`	# Causes Error: "unescaped newline inside substitute pattern", for the backquoted command (it would be OK without backqoutes).  Not sure why.  So, the Database passwords that contain a backshash are not accepted.
dbpassquoted=$dbPassword
com1=`echo $com | sed 's/:@@@@@/:*****@/'`
com2=`echo $com | sed 's/:@@@@@/:'$dbpassquoted'@/'`
echo "% $com1"
[ $dryrun = "TRUE" ] || eval $com2	# eval to deal with the case the Site-name contains a space(s).
exitstatus=$?
if [ $dryrun != "TRUE" -a "$exitstatus" -ne 0 ]; then
  echo "Failed." >&2
  exit $exitstatus
fi
 
# Download modules and themes
##########################################################
com="drush -y dl \
ctools \
variable \
token \
entity \
views \
i18n \
i18nviews \
l10n_update \
admin_menu \
module_filter \
devel"

echo "% "`echo $com | tr '\012' ' '`
[ $dryrun = "TRUE" ] || $com || midexitstatus="FAILED"
 
# Disable some core modules
##########################################################
com="drush -y dis \
color \
toolbar \
shortcut";

echo "% "`echo $com | tr '\012' ' '`
[ $dryrun = "TRUE" ] || $com || midexitstatus="FAILED"
 
# Enable modules
##########################################################
com="drush -y en \
entity \
views \
views_ui \
token \
i18n \
l10n_update \
i18nviews \
admin_menu \
admin_menu_toolbar \
module_filter \
devel";

echo "% "`echo $com | tr '\012' ' '`
[ $dryrun = "TRUE" ] || $com || midexitstatus="FAILED"
 

# Post-install settings
##########################################################
# disable user pictures
com="drush vset -y user_pictures 0";
echo "% $com"
[ $dryrun = "TRUE" ] || $com || midexitstatus="FAILED"
# allow only admins to register users
com="drush vset -y user_register 0";
[ $dryrun = "TRUE" ] || $com || midexitstatus="FAILED"
# set site slogan
com="drush vset -y site_slogan '$siteSlogan'";
[ $dryrun = "TRUE" ] || eval $com || midexitstatus="FAILED"	# eval to deal with the case the slogan contains a space(s).
 

echo "/***************************************************"
if [ $dryrun = "TRUE" ]; then
  echo "// Dryrun...  (Now, run without the -n option!)"
  exit 0
elif [ $midexitstatus = "SUCCESS" ]; then
  echo "// Install completed successfully."
else
  echo "// Install finished with some failures (see the STDOUT output)."
  exit 2
fi
echo "***************************************************/"
