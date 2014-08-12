hitrack_check_bs4.py and hitrack_check_lxml.py 
These two scripts do exectly the same: connect to your local Hitrack server, search for a storage arrays' name that matches any in the globalArrays list and display its status. The only difference is that the former uses BeautifulSoup whilsts the latter lxml library to parse html.

hdbsql2mysqlfix.py                             
A simple script I used during the migration of OpenFire from HSQLDB to MySQL and had to convert UPPER CASED names of the tables into a camle back format.            
