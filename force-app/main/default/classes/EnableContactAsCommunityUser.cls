public without Sharing class EnableContactAsCommunityUser{
    
    @AuraEnabled
    public static String createCommuinityUser(String recordId){
        Profile pf = [Select id,name from Profile where name ='TB Members Plus' limit 1];
        Contact con =   [SELECT id,name,email,lastname,firstname,
                        accountid,
                        account.name,
                        npsp__Primary_Affiliation__c,
                        npsp__Primary_Affiliation__r.parent.name,
                        npsp__Primary_Affiliation__r.parentId
                        FROM contact 
                        WHERE Id=:recordId LIMIT 1];
        
            if(con.npsp__Primary_Affiliation__c == null){
                return 'User is NOT enabled. Primary Affiliation is missing.';
            }else if(con.npsp__Primary_Affiliation__r.parent == null){
                return 'User is NOT enabled. Agency is missing the parent organization.';
            }

            User usr = new User();
            usr.contactId=con.Id;
            usr.username=con.Email+'.TB';
            usr.firstname=con.FirstName;
            usr.lastname=con.LastName;
            usr.email=con.Email;
            usr.communityNickname = con.LastName+'_'+con.FirstName+'_TB';
            usr.alias = string.valueof(con.FirstName.substring(0,1) + con.LastName.substring(0,1));
            usr.profileid = pf.Id;
            usr.emailencodingkey='UTF-8';
            usr.languagelocalekey='en_US';
            usr.localesidkey='en_US';
            usr.timezonesidkey='America/Los_Angeles';
            usr.ToolBank_Affiliate_of_Agency__c = (con.npsp__Primary_Affiliation__c != null? con.npsp__Primary_Affiliation__r.parent.name:con.account.name);
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.EmailHeader.triggerUserEmail= true;
            Database.saveresult sr = Database.insert(usr,dlo);
        
        
        //system.Site.createExternalUser(usr,con.accountid,'4444444',true);
        if (!sr.isSuccess()) {
            for(Database.Error err: sr.getErrors()){
                throw new AuraHandledException(err.getMessage());
            }
        }else{
            insert new Affiliate_Account__c(Affiliate__c = (con.npsp__Primary_Affiliation__c != null? con.npsp__Primary_Affiliation__r.parentId:con.accountId), user__c = usr.Id);
            setPassword(usr.Id);
        }

        return 'Success';
    }

    @future
    public static void setPassword(String userId){

        system.resetPassword(userId,true);
        User usr = [SELECT Id,username, ContactId FROM USER WHERE Id=:userId];
        contact con = new contact(id=usr.ContactId,username__c =usr.username);

        update con;
    }

    @AuraEnabled
    public static string resetPassword(String recordId){

        system.debug('contactId :: '+recordId);
        User usr = [SELECT Id,username, ContactId FROM USER WHERE contactID=:recordId LIMIT 1];
        system.resetPassword(usr.Id,true);
        
        return 'Success';
    }

   

    @AuraEnabled
    public static string disableContact(String recordId){
       // contactId=recordId;
        //disableContactAsync(recordId);
        Generic_Event__e  gEvent = new Generic_Event__e();
        gEvent.RecordId__c = recordId;
        EventBus.publish(gEvent);
        return 'Success';
    }

    //@future
    public static void disableContactAsync(List<Generic_Event__e> eventList){
        system.debug('contactId :: '+eventList);
        string contactId;
        for(Generic_Event__e ge: eventList){
            contactId = ge.recordId__c;
            break;
        }
        User usr = [SELECT Id,communityNickname, ContactId FROM USER WHERE contactId =:contactId LIMIT 1];
        usr.isActive = false;
        Integer IntrandomNumber = Integer.valueof((Math.random() * 10000));
        usr.communityNickname = usr.communityNickname+'_'+IntrandomNumber;
        usr.IsPortalEnabled = false;
        
            if(!Test.isRunningTest()){
                update usr;
                disableContactFlag(contactId);
            }
    }

    @future
    public static void disableContactFlag(String recordId){

        
        contact con = new contact(id=recordId, user_enabled__c = false,User_Disabled_Date__c = System.today());

        update con;
    }


}