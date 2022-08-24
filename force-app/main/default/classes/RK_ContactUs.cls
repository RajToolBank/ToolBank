public class RK_ContactUs {
    
    public list<BusinessHours> businessHours{set;get;}
    public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public list<BusinessHours> bHours{set;get;}
    List<businessWrapper> listBusinessHours = new List<businessWrapper>();
    public RK_ContactUs() {
        system.debug('********** START OF HelpPageForCustomerCommunity.cls');
        String parentAccountName = [Select contactId, Contact.Account.Parent.Name from user where id=:userinfo.getuserid()].Contact.Account.Parent.Name;
        system.debug('parent account name-->'+parentAccountName);
        getData = [Select Id, DeveloperName, Affiliate_Address__c, Affiliate_Email__c, Affiliate_Phone_number__c, Note_to_the_Agency__c, 
                   Remaining_Address__c, Street__c, Website__c from Toolbank_Help_Page__mdt where DeveloperName = :parentAccountName];
        system.debug('getData-->'+getData);
        bHours = [SELECT Id, Name,IsActive, SundayStartTime,SundayEndTime, MondayStartTime, MondayEndTime, 
                  TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
                  ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime FROM BusinessHours where IsActive =True and Name = :parentAccountName];
        system.debug('bHours-->'+bHours);
        system.debug('********** END OF HelpPageForCustomerCommunity.cls');
    } 
    public static String getTimeInAMPM(Time t) {
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
    
}