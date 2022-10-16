global class RK_AccountExpirationEmailAlertBatch implements Database.Batchable<sObject> {
    
    public Date currentDate = Date.today();
    public Date currentDate2 = Date.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
    public Date targetDate = currentDate2.addDays(30);
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug(targetDate);
        String query = 'select Id, Name, npo02__MembershipEndDate__c from Account where npo02__MembershipEndDate__c != null and npo02__MembershipEndDate__c = :targetDate';
        system.debug(query);
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<Account> accList) {       
        EmailTemplate emailTemplate = [select Id, Body from EmailTemplate where DeveloperName = 'Toolbank_Membership_Expires_30_Days_End_User'];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Contact con :[Select Id, Email,Name, Primary_Contact__c, AccountId from Contact where AccountId In :accList and Primary_Contact__c = true]) {
            System.debug(con);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {con.Email});
            email.setSaveAsActivity(false);
            email.setTargetObjectId(con.Id);
            email.setTemplateId(emailTemplate.Id);
            email.setWhatId(con.AccountId);
            emailList.add(email);
        }
        if(!emailList.IsEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            for(Messaging.SendEmailResult result :results) {
                if (result.success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: '+ results[0].errors[0].message);
                }
            }
        }      
    }  
    global void finish(Database.BatchableContext BC) {
    }
}