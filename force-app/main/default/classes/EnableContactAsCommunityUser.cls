public class EnableContactAsCommunityUser {
    
    @AuraEnabled
    public static String createCommuinityUser(String recordId){
        System.debug('recordId :: '+recordId);
        Profile pf = [Select id,name from Profile where name ='TB Members' limit 1];
        Contact con = [select id,name,email,lastname,firstname,accountid from contact where Id=:recordId limit 1];
        String Rnd = '';
        User usr = new User();
        usr.contactId=con.Id;
        usr.username=con.Email;
        usr.firstname=con.FirstName;
        usr.lastname=con.LastName;
        usr.email=con.Email;
        usr.communityNickname = con.LastName+'_'+con.FirstName;
        usr.alias = string.valueof(con.FirstName.substring(0,1) + con.LastName.substring(0,1));
        usr.profileid = pf.Id;
        usr.emailencodingkey='UTF-8';
        usr.languagelocalekey='en_US';
        usr.localesidkey='en_US';
        usr.timezonesidkey='America/Los_Angeles';
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail= true;
        Database.saveresult sr = Database.insert(usr,dlo);

        return 'Success';
    }
}