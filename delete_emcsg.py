#!/usr/bin/python
 
import sys, subprocess
from lxml import etree
 
sgname = ""
sid = ""
symdevs = []
mvname = ""
initiators = []
igwwn = {}
symfast = False
policyname = ""
 
def usage(name):
    print name + " [sid] [storage groupname]:"
    print "     sid                - VMAX System ID."
    print "     storage group name - VMAX Storage group to clean up."
    print ""
 
def getSgDevices():
    global mvname, symdevs
 
    cmd = "symaccess -sid " + sid + " show " + sgname + " -type storage -output xml"
 
    result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    sgtree_xml = result.communicate()[0]
 
    if result.returncode != 0:
        print "SYM CLI (SG) command finished with the error."
        sys.exit(-1)
 
    sgtreeroot = etree.fromstring(sgtree_xml)
 
    for elem in sgtreeroot.iterfind("Symmetrix/Storage_Group/Group_Info/Device"):
        symdevs.append(elem.find("start_dev").text)
 
    for elem in sgtreeroot.iterfind("Symmetrix/Storage_Group/Group_Info/Mask_View_Names"):
        mvname = elem.find("view_name").text
 
def getMaskingView(mv):
    global initiators
 
    cmd = "symaccess -sid " + sid + " show view " + mv + " -output xml"
    result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    mvtree_xml = result.communicate()[0]
 
    if result.returncode != 0:
        print "SYM CLI (MV) command finished with the error."
        sys.exit(-1)
 
    mvtreeroot = etree.fromstring(mvtree_xml)
 
    for elem in mvtreeroot.iterfind("Symmetrix/Masking_View/View_Info/Initiators"):
        initiators = [i.text for i in elem.findall("group_name")]
 
    for elem in mvtreeroot.iterfind("Symmetrix/Masking_View/View_Info"):
        initiators.append(elem.find("init_grpname").text)
 
def getWWN(ig):
    global igwwn
    for iname in ig:
        cmd = "symaccess -sid " + sid + " show " + iname + " -type initiator -output xml"
        result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        igtree_xml = result.communicate()[0]
 
        if result.returncode != 0:
            print "SYM CLI (IG) command finished with the error."
            sys.exit(-1)
 
        igtreeroot = etree.fromstring(igtree_xml)
        for elem in igtreeroot.iterfind("Symmetrix/Initiator_Group/Group_Info/Initiators"):
            try:
                igwwn[iname] = elem.find("wwn").text
            except AttributeError:
                pass
 
def getSymFast(sg):
    global symfast, policyname
 
    cmd = "symfast -sid " + sid + " show -association -sg " + sg + " -output xml"
    result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    fp_xml = result.communicate()[0]
    if result.returncode != 0:
        print "SYM CLI (FP) command finished with the error."
        sys.exit(-1)
 
    fptreeroot = etree.fromstring(fp_xml)
    for elem in fptreeroot.iterfind("Symmetrix/Storage_Association/Policy_info"):
        policyname = elem.find("policy_name").text
        symfast = True
 
if __name__ == '__main__':
    if len(sys.argv) != 3:
        usage(sys.argv[0])
        sys.exit(-1)
 
    sid = str(sys.argv[1])
    sgname = str(sys.argv[2])
 
    getSgDevices()
    getMaskingView(mvname)
    getWWN(initiators)
    getSymFast(sgname)
 
    print "symdev -sid " + sid + " -devs " + ",".join(str(dev) for dev in symdevs) + " not_ready"
    print "symaccess -sid " + sid + " delete view -name " + mvname
    for key in igwwn:
        print "symaccess -sid " + sid + " -name " + key + " -type initiator -wwn " + igwwn[key] + " remove"
    for ig in initiators:
        print "symaccess -sid " + sid + " delete -name " + ig + " -type initiator"
    if symfast:
        print "symfast -sid " + sid + " disassociate -fp_name " + policyname + " -sg " + sgname
    print "symaccess -sid " + sid + " -name " + sgname + " -type storage remove devs" + " " + ",".join(str(dev) for dev in symdevs)
    print "symaccess -sid " + sid + " delete -name " + sgname + " -type storage"