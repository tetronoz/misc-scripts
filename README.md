###hitrack_check_bs4.py and hitrack_check_lxml.py<br>
These two scripts do exectly the same: connect to your local Hitrack server, search for a storage arrays' name that matches any in the globalArrays list and display its status. The only difference is that the former uses BeautifulSoup whilsts the latter lxml library to parse html.<p>
###hdbsql2mysqlfix.py<br>
A simple script I used during the migration of OpenFire from HSQLDB to MySQL and had to convert UPPER CASED names of the tables into a camle back format.<p>
###delete_emcsg.py<br>
Quick and dirty way to generate EMC SYM CLI commands in the right order to remove a storage group. TDEVs are left intact and you will need to delete them separately.<p>
###get_brocade_cmd.pl<br> 
This script connects to a defined list of Brocade SAN switches, dumps the output of such commands like "switchshow", "cfgshow", etc. (the list could be configured separately),<p>
stores it locally and diffs the produced result with the data which were dumped  on the day before.<p>
Could be quite handy to track the changes in the Brocade’s configuration. 
