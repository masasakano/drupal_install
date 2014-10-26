Script to automate installing Drupal by drush

Overview
--------
This script makes a clean install of Drupal to a specified directory,
using drush.

Drush must be in the command-line search path.
The database table and user with appropriate priviledge for the table
must be already there (this script does NOT create the database).
The names of database table and its user (for Drupal) are assumed
to be identical.
The password for the database is prompted to input.
Note I have tested this script only with MySQL.

The password for the site administrator is set to be the same
as the (specified) username.

You can change the hard-coded variables to modify those parameters,
as well as installed and enabled (and disabled) modules.

Important note
--------------
The root directory Drupal is installed to will be completely
overwritten, that is, it will be deleted and recreated.
Any subdirectories under the root directory will be the same.
Therefore, if you specify the existing and non-empty directory,
make sure that is what you would want!

Usage
-----
% sh drupal_install.sh [-h] [Options] -d Directory < DB-Password
 1-line is (silently) read from STDIN: MySql database password.
 Options:
  -h: Help (and exit)
  -n: Dryrun
  -f: Force - mkdir if the directory does not exist or destroy if contents exist
  -d: (Mandatory) Installing directory
    NOTE: The directory should be empty (unless -f option is specified)!
  -f: mkdir if the directory does not exist (even if -n is specified)
  -d: (Mandatory) Installing directory
  -u,-m: Username(=Password), mail address of Administrator
  -q: Database name(=Database-user)
  -t: Site Title  (Def: 'Drupal Example')
  -s: Site Slogan (Def: 'Get the example right!')
  -l: Site Locale (Def: gb)

Install
-------
Place the script wherever you like, and run it with
 % sh ScriptName

Known issues
------------
None.

Future developments
-------------------
Nothing planned.

Disclaimer
----------
Please use it at your own risk.

Acknowledgements 
----------------
I thank the Drupal community!

Authors
-------
Masa Sakano - http://www.drupal.org/user/3022767

