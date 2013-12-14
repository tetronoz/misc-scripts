import re
 
if __name__ == "__main__":
    tables = ["ofConParticipant","ofConversation", "ofExtComponentConf", "ofGroup", "ofGroupProp", "ofGroupUser",
              "ofID", "ofMessageArchive", "ofMucAffiliation", "ofMucConversationLog", "ofMucMember", "ofMucRoom",
              "ofMucRoomProp", "ofMucService", "ofMucServiceProp", "ofOffline", "ofPresence", "ofPrivacyList",
              "ofPrivate", "ofProperty", "ofPubsubAffiliation", "ofPubsubDefaultConf", "ofPubsubItem", "ofPubsubNode",
              "ofPubsubNodeGroups", "ofPubsubNodeJIDs", "ofPubsubSubscription", "ofRRDs", "ofRemoteServerConf",
              "ofRoster", "ofRosterGroups", "ofSASLAuthorized", "ofSecurityAuditLog", "ofUser", "ofUserFlag",
              "ofUserProp", "ofVCard", "ofVersion"]
 
 
# INSERT INTO `PUBLIC`.`OFCONPARTICIPANT`(`CONVERSATIONID`, `JOINEDDATE`, `LEFTDATE`, `BAREJID`, `JIDRESOURCE`, `NICKNAME`)
# will be converted into
# insert into `openfire`.ofConParticipant`(`conversationid`, `joineddate`, `leftdate`, `barejid`, `jidresource`, `nickname`)
 
    fp = open("Inserts.sql", mode="r")
    fp1 = open("Inserts1.sql", mode='w')
    for line in fp.readlines():
        m = re.search(r'`PUBLIC`.`(.+)`\((.*)\)', line, re.I)
        if m:
            table_upper = m.group(1)
            rest = m.group(2).lower()
 
            for t in tables:
                if t.upper() == table_upper:
                    l = "insert into `openfire`.`" + t + "`(" + rest + ")"
                    fp1.write(l)
        else:
            fp1.write(line)
    fp.close()
    fp1.close()