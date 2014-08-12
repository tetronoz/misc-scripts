#!/usr/bin/python
 
import requests
from lxml import html, etree
 
moscowArrays = ['moscow_array1', 'moscow_array2']
internationalArrays = ['int_array1', 'int_array2']
 
globalArrays = []
globalArrays = moscowArrays + internationalArrays
 
hitrack_urls = ['http://moscowHitrack:6696/', 'http://intHitrack:6696']
hitrack_sites = ['Moscow', 'International']
 
def checkHitrack(url, site):
    print(site)
    session = requests.session()
    loginData = {'ListId': 'Administrator', 'pword': 'hds'}
    session.post(url+'CGI-LOGON', data = loginData)
    r = session.get(url+'CGI-SUMMARY')
 
    tree = html.document_fromstring(r.text)
    rows = tree.xpath('//table[@border="" and @cols="11" and @width="100%"]/tr')
    for row in rows:
        if len(row) > 0 and list(row)[1].text in globalArrays:
            print (list(row)[1].text + " " + list(row)[7].xpath("string()"))
 
if __name__ == '__main__':
    for url, site in zip(hitrack_urls, hitrack_sites):
        checkHitrack(url, site)
        print ("")