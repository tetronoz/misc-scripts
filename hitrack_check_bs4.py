#!/usr/bin/python
 
import requests
from bs4 import BeautifulSoup
 
moscowArrays = ['moscow_array1', 'moscow_array2']
internationalArrays = ['int_array1', 'int_array2']
 
globalArrays = []
globalArrays = moscowArrays + internationalArrays
 
hitrack_urls = ['http://moscowHitrack:6696/', 'http://intHitrack:6696']
hitrack_sites = ['Moscow', 'International']

def checkHitrack(url, site):
    status = None
    print(site)
    session = requests.session()
    loginData = {'ListId': 'Administrator', 'pword': 'hds'}
    session.post(url+'CGI-LOGON', data = loginData)
    r = session.get(url+'CGI-SUMMARY')
 
    soup = BeautifulSoup(r.text)
    table = soup.find_all("table")[3]
    rows = table.find_all("tr")
    for row in rows:
        col =  row.find_all("td")
        if len(col) > 0 and col[1].string in globalArrays:
            for s in col[7].strings:
                status = s
            print (col[1].string + " " + status)
 
if __name__ == '__main__':
    for url, site in zip(hitrack_urls, hitrack_sites):
        checkHitrack(url, site)
        print ("")
 