public without Sharing class EnableContactAsCommunityUser {
    
    @AuraEnabled
    public static String createCommuinityUser(String recordId){
        Profile pf = [Select id,name from Profile where name ='TB Members Plus' limit 1];
        Contact con = [select id,name,email,lastname,firstname,accountid from contact where Id=:recordId limit 1];
        String Rnd = '';
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
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail= true;
        Database.saveresult sr = Database.insert(usr,dlo);

        
        //system.Site.createExternalUser(usr,con.accountid,'4444444',true);
        if (!sr.isSuccess()) {
            for(Database.Error err: sr.getErrors()){
                throw new AuraHandledException(err.getMessage());
            }
        }else{
            insert new Affiliate_Account__c(Affiliate__c = con.accountid, user__c = usr.Id);
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

}