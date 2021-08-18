### hitrack_check_bs4.py and hitrack_check_lxml.py
These two scripts do exectly the same: connect to your local Hitrack server, search for a storage arrays' name that matches any in the globalArrays list and display its status. The only difference is that the former uses BeautifulSoup whilsts the latter lxml library to parse html.

### hdbsql2mysqlfix.py
A simple script I used during the migration of OpenFire from HSQLDB to MySQL and had to convert UPPER CASED names of the tables into a camle back format.

### delete_emcsg.py
Quick and dirty way to generate EMC SYM CLI commands in the right order to remove a storage group. TDEVs are left intact and you will need to delete them separately.

### get_brocade_cmd.pl 
This script connects to a defined list of Brocade SAN switches, dumps the output of the commands like "switchshow", "cfgshow", etc. (the list could be configured separately),
stores it locally and diffs the produced result with the data which were dumped  on the day before.
Could be quite handy to track the changes in the Brocade’s configuration. 
