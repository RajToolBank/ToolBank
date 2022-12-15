public without sharing class RK_ContactUs {
    
    //public list<BusinessHours> businessHours{set;get;}
    //public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public user user {get;set;}
    public string address{get;set;}
    public list<BusinessHours> bHours{set;get;}
    public Account account {get;set;}
   // List<businessWrapper> listBusinessHours = new List<businessWrapper>();
    public RK_ContactUs() {
        system.debug('********** START OF HelpPageForCustomerCommunity.cls');//Contact.Account.Parent.Name
        user = [SELECT contactId,
                Contact.Account.Parent.BillingStreet,
                Contact.Account.Parent.billingcity,
                Contact.Account.Parent.billingState,
                Contact.Account.Parent.billingPostalCode,
                Contact.Account.Parent.billingCountry, 
                Contact.Account.Parent.Phone,
                Contact.Account.Parent.Generic_Org_Email__c,
                Contact.Account.Parent.website,
                Contact.Account.Parent.Name,
                Contact.Account.Parent.Note_To_Agency__c,
                Contact.Account.Parent.Sunday_Start_Time__c,
                Contact.Account.Parent.Sunday_End_Time__c,
                Contact.Account.Parent.Monday_Start_Time__c,
                Contact.Account.Parent.Thursday_Start_Time__c,
                Contact.Account.Parent.Monday_End_Time__c,
                Contact.Account.Parent.Tuesday_Start_Time__c,
                Contact.Account.Parent.Thursday_End_Time__c,
                Contact.Account.Parent.Tuesday_End_Time__c,
                Contact.Account.Parent.Friday_Start_Time__c,
                Contact.Account.Parent.Wednesday_Start_Time__c,
                Contact.Account.Parent.Friday_End_Time__c,
                Contact.Account.Parent.Wednesday_End_Time__c,
                Contact.Account.Parent.Saturday_Start_Time__c,
                Contact.Account.Parent.Saturday_End_Time__c,
                Contact.Account.Parent.Id,
                Contact.Account.ParentId,
                
                Contact.npsp__Primary_Affiliation__r.Parent.BillingStreet,
                Contact.npsp__Primary_Affiliation__r.Parent.billingcity,
                Contact.npsp__Primary_Affiliation__r.Parent.billingState,
                Contact.npsp__Primary_Affiliation__r.Parent.billingPostalCode,
                Contact.npsp__Primary_Affiliation__r.Parent.billingCountry, 
                Contact.npsp__Primary_Affiliation__r.Parent.Phone,
                Contact.npsp__Primary_Affiliation__r.Parent.Generic_Org_Email__c,
                Contact.npsp__Primary_Affiliation__r.Parent.website,
                Contact.npsp__Primary_Affiliation__r.Parent.Name,
                Contact.npsp__Primary_Affiliation__r.Parent.Note_To_Agency__c,
                contact.npsp__Primary_Affiliation__c,
                contact.npsp__Primary_Affiliation__r.Id,
                Contact.npsp__Primary_Affiliation__r.Parent.Sunday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Sunday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Monday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Thursday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Monday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Tuesday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Thursday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Tuesday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Friday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Wednesday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Friday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Wednesday_End_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Saturday_Start_Time__c,
                Contact.npsp__Primary_Affiliation__r.Parent.Saturday_End_Time__c
                FROM user 
                WHERE id =: userinfo.getuserid()];
        
        if(user.Contact.npsp__Primary_Affiliation__c != null)
        account = user.Contact.npsp__Primary_Affiliation__r.Parent;
        else account = user.Contact.Account.Parent;

        address =   account?.BillingStreet +'\n'
                    +account?.billingcity+', '
                    +account?.billingState+', '
                    +account?.billingPostalCode+', '
                    +account?.billingCountry;
String parentAccountName = account?.Name;
        if(Test.isRunningTest())
            parentAccountName = 'ToolBank_Training_Org';
        system.debug('parent account name-->'+parentAccountName);
        //getData = [Select Id, DeveloperName, Affiliate_Address__c, Affiliate_Email__c, Affiliate_Phone_number__c, Note_to_the_Agency__c, 
          //         Remaining_Address__c, Street__c, Website__c from Toolbank_Help_Page__mdt where MasterLabel = :parentAccountName];
        //system.debug('getData-->'+getData);
        bHours = [SELECT Id, Name,IsActive, SundayStartTime,SundayEndTime, MondayStartTime, MondayEndTime, 
                  TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
                  ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime FROM BusinessHours where IsActive =True and Name = :parentAccountName];
        system.debug('bHours-->'+bHours);
        system.debug('********** END OF HelpPageForCustomerCommunity.cls');
    } 
    /* public static String getTimeInAMPM(Time t) {
        Integer hour=t.hour();
        String timewithAMPM=t.minute()<>0?((hour>=12)?(String.valueof(hour - 12) +':'+t.minute()+ ' PM'):(String.valueof(hour)) +':'+t.minute() + ' AM'):((hour>=12)?(String.valueof(hour - 12)+':'+t.minute() +'0 PM'):(String.valueof(hour)) +':'+t.minute() + '0 AM');
            return timewithAMPM;
    }
   public List<businessWrapper> getListBusinessHours() {
        for(BusinessHours bHr : bHours) {
            businessWrapper bWrapper = new businessWrapper();
            bWrapper.Name = bHr.Name;
            if(String.valueOf(bHr.SundayStartTime) == null) {
                bWrapper.SundayStartTime = '00:00';
            }
            else {
                bWrapper.SundayStartTime =  getTimeInAMPM(bHr.SundayStartTime);     
            }
            if(String.valueOf(bHr.SundayEndTime) == null){
                bWrapper.SundayEndTime = '00:00';
            }
            else{
                bWrapper.SundayEndTime =  getTimeInAMPM(bHr.SundayEndTime);     
            }
            if(String.valueOf(bHr.MondayStartTime) == null){
                bWrapper.MondayStartTime = '00:00';
            }
            else{
                bWrapper.MondayStartTime =  getTimeInAMPM(bHr.MondayStartTime);     
            }
            if(String.valueOf(bHr.MondayEndTime) == null){
                bWrapper.MondayEndTime = '00:00';
            }
            else{
                bWrapper.MondayEndTime =  getTimeInAMPM(bHr.MondayEndTime);     
            }
            if(String.valueOf(bHr.TuesdayStartTime) == null){
                bWrapper.TuesdayStartTime = '00:00';
            }
            else{
                bWrapper.TuesdayStartTime =  getTimeInAMPM(bHr.TuesdayStartTime);     
            }
            if(String.valueOf(bHr.TuesdayEndTime) == null){
                bWrapper.TuesdayEndTime = '00:00';
            }
            else{
                bWrapper.TuesdayEndTime =  getTimeInAMPM(bHr.TuesdayEndTime);     
            }
            if(String.valueOf(bHr.WednesdayStartTime) == null){
                bWrapper.WednesdayStartTime = '00:00';
            }
            else{
                bWrapper.WednesdayStartTime =  getTimeInAMPM(bHr.WednesdayStartTime);     
            }
            if(String.valueOf(bHr.WednesdayEndTime) == null){
                bWrapper.WednesdayEndTime = '00:00';
            }
            else{
                bWrapper.WednesdayEndTime =  getTimeInAMPM(bHr.WednesdayEndTime);     
            }
            if(String.valueOf(bHr.ThursdayStartTime) == null){
                bWrapper.ThursdayStartTime = '00:00';
            }
            else{
                bWrapper.ThursdayStartTime =  getTimeInAMPM(bHr.ThursdayStartTime);     
            }
            if(String.valueOf(bHr.ThursdayEndTime) == null){
                bWrapper.ThursdayEndTime = '00:00';
            }
            else{
                bWrapper.ThursdayEndTime =  getTimeInAMPM(bHr.ThursdayEndTime);     
            }
            if(String.valueOf(bHr.FridayStartTime) == null){
                bWrapper.FridayStartTime = '00:00';
            }
            else{
                bWrapper.FridayStartTime =  getTimeInAMPM(bHr.FridayStartTime);     
            }
            if(String.valueOf(bHr.FridayEndTime) == null){
                bWrapper.FridayEndTime = '00:00';
            }
            else{
                bWrapper.FridayEndTime =  getTimeInAMPM(bHr.FridayEndTime);     
            }
            if(String.valueOf(bHr.SaturdayStartTime) == null){
                bWrapper.SaturdayStartTime = '00:00';
            }
            else{
                bWrapper.SaturdayStartTime =  getTimeInAMPM(bHr.SaturdayStartTime);     
            }
            if(String.valueOf(bHr.SaturdayEndTime) == null){
                bWrapper.SaturdayEndTime = '00:00';
            }
            else{
                bWrapper.SaturdayEndTime =  getTimeInAMPM(bHr.SaturdayEndTime);     
            }
            listBusinessHours.add(bWrapper);
        }
        return listBusinessHours;
    }
    public class businessWrapper
    {
        public String Name{get; set;}
        public String SundayStartTime{get; set;}
        public String SundayEndTime{get; set;}
        public String MondayStartTime{get; set;}
        public String MondayEndTime{get; set;}
        public String TuesdayStartTime{get; set;}
        public String TuesdayEndTime{get; set;}
        public String WednesdayStartTime{get; set;}
        public String WednesdayEndTime{get; set;}
        public String ThursdayStartTime{get; set;}
        public String ThursdayEndTime{get; set;}
        public String FridayStartTime{get; set;}
        public String FridayEndTime{get; set;}
        public String SaturdayStartTime{get; set;}
        public String SaturdayEndTime{get; set;}
        
        public businessWrapper(){}
    }
    */
}