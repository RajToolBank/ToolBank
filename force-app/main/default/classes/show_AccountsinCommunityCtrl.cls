public class show_AccountsinCommunityCtrl {
    public string name {get;set;}
    public String Phone {get;set;}
    public string Billingaddress{get;set;}
    public String BillingStreet {get;set;}
    public string BillingCity{get;set;}
    public String BillingState{get;set;}
    public string BillingCountry{get;set;}
    public String BillingPostalCode {get;set;}
    public String website{get; set;}
    public String annualbudget{get; set;}
    public String agencyImpact {get;set;}
    public String agencyMission {get;set;}
    public String staffFT {get;set;}
    public String staffPT {get;set;}
    public String insta {get;set;}
    public String face {get;set;}
    public String tweet {get;set;}
    public string ids{get;set;}
    public String conEdit{get;set;}
    public String memberexpDate{get; set;}
    public String memberStatus{get;set;}
    public String memberstartDate{get;set;}
    public contact getcont{get;set;}
    Public Account accDetails {Set;Get;}
    public boolean panel1{get;set;}
    public boolean panel2{get; set;}
    public boolean panel3{get; set;}
    public Contact getcontc {get; set;}
    public Boolean primaryId{get; set;}
    public Boolean ExecutivecontactId{get; set;}
    //public String accLoc{get;set;}
    public String accId{get;set;}
    public Boolean showAccount {get;set;}  
    public Boolean hideAccount {get;set;}
    public List<Contact> deleteContact {get;set;}
    
    public string affiliateContact {get;set;}
    public string affiliateEmail {get;set;}
    public string affiliatePhone {get;set;}
    public string warehouseManager {get;set;}
    public string warehouseManagerEmail {get;set;}
    public string warehouseManagerPhone {get;set;}
    
    public show_AccountsinCommunityCtrl(){
        size=3;
        showAccount= true;
        hideAccount = false;
        deleteContact = new List<Contact>();    
        getcont = new contact();
        getcontc = new contact();
        accId = [Select contactId from user where id=:userinfo.getuserid()].ContactId;
        primaryId = [Select Contact.Primary_contact__c from user where id=:userinfo.getuserid()].Contact.Primary_contact__c;
        System.debug(PrimaryId);
        ExecutivecontactId = [Select Contact.Executive_Contact__c from user where id=:userinfo.getuserid()].Contact.Executive_Contact__c;
        System.debug(ExecutivecontactId);
        System.debug(accId );
        accDetails  = [Select id,Name,Affiliate_Email__c,Affiliate_Phone__c,owner.name, Warehouse_Manager__c,Warehouse_Manager__r.name, Warehouse_Manager_Email__c,Warehouse_Manager_Phone__c,Phone,Billingaddress,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,website,annual_budget__c,
                       Membership_Expiration_Date__c,Membership_Start_Date__c,Agency_Impact__c,Agency_Mission__c ,PT__c,FT__c,
                       Instagram__c,Facebook__c,twitter__c,Membership_Status__c
                       from Account 
                       where id=:[select AccountId from Contact where id=:accId ].AccountId ];
        System.debug('##'+accDetails);
        name = accDetails.Name;
        Phone =accDetails.Phone;
        
        BillingStreet=accDetails.BillingStreet;
        BillingCity= accDetails.BillingCity;
        BillingState=accDetails.BillingState;
        BillingCountry= accDetails.BillingCountry;
        BillingPostalCode =accDetails.BillingPostalCode ;
        website=accDetails.website;
        annualbudget=accDetails.annual_budget__c;
        memberexpDate=String.valueOf(accDetails.Membership_Expiration_Date__c);
        memberStatus=accDetails.Membership_Status__c;
        memberstartDate=String.valueof(accDetails.Membership_Start_Date__c);
        ids=accDetails.id;
        //accLoc=accDetails.Parent.Community_URL_Prefix__c;
        agencyImpact = accDetails.Agency_Impact__c;
        agencyMission=accDetails.Agency_Mission__c;
        if(accDetails.PT__c!=null)
            staffPT=String.valueof(accDetails.PT__c);
        system.debug('PT'+staffPT);
        if(accDetails.FT__c!=null)
            staffFT=String.valueof(accDetails.FT__c);
        insta=accDetails.Instagram__c;
        face=accDetails.Facebook__c;
        tweet=accDetails.twitter__c;
        
        affiliateContact  = accDetails.owner.name;
        affiliateEmail = accDetails.Affiliate_Email__c;
        affiliatePhone = accDetails.Affiliate_Phone__c;
        warehouseManager = accDetails.Warehouse_Manager__r.name;
        warehouseManagerEmail = accDetails.Warehouse_Manager_Email__c;
        warehouseManagerPhone = accDetails.Warehouse_Manager_Phone__c;
        
        panel1=false;
    }
    
    public pagereference showSec(){
        panel1=false;
        panel2=true;
        return null;
    }
    
    public Pagereference insertContact(){
        panel1=false;
        panel2=false;
        getcontc.AccountId=ids;
        if(!Test.isRunningTest()) {
            insert getcontc;
        }
        getcontc = new contact();
        getcont = new contact();
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
            [select id,name,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,Status__c,Unsubscribe_Notifications__c,Executive_Home_Phone__c,
             (select id,username from users) from contact where AccountId=:ids ]));
        setCon.setPageSize(size);  
        noOfRecords = setCon.getResultSize();
        getContacts();
        System.debug('idsss'+getcont);
        
        return null;
    }
    
    public PageReference editContact(){
        panel1=true;
        panel2=false;
        System.debug('Hi'+getcontc);
        System.debug('ConId'+conEdit);
        System.debug('ids-->'+ids);
        getcont = [select id,FirstName,lastname,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,Status__c,Unsubscribe_Notifications__c,Executive_Home_Phone__c,
                   (select id,username from users) from contact where AccountId=:ids and id=:conEdit];
        System.debug('Contlist'+getcont.FirstName);
        return null;
    }
    public pageReference updateContact(){
        try{
            panel1=false;
            panel2=false;
            update getcont;
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                [select id,name,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,Status__c,Executive_Home_Phone__c,
                 Unsubscribe_Notifications__c,(select id,username from users) from contact where AccountId=:ids ]));
            setCon.setPageSize(size);  
            noOfRecords = setCon.getResultSize();
            getContacts();
        }
        catch(Exception e)
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.Severity.Error,'Make another contact as Primary before removing this contact as Primary.'));
        } 
        return null;
    }
    public PageReference cancelContact(){
        panel1=false;
        panel2=false;
        return null;
    }
    public PageReference viewAllContacts(){
        panel1=false;
        panel2=false;
        panel3=true;
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
            [select id,name,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,Status__c,Executive_Home_Phone__c,
             Unsubscribe_Notifications__c,(select id,username from users) from contact where AccountId=:ids ]));
        getContacts();
        return null;
    }
    public PageReference goBack(){
        panel1=false;
        panel2=false; 
        panel3=false;                
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
            [select id,name,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,Status__c,Executive_Home_Phone__c,
             Unsubscribe_Notifications__c,(select id,username from users) from contact where AccountId=:ids ]));
        setCon.setPageSize(size);  
        noOfRecords = setCon.getResultSize();
        
        getContacts();
        return null;
    }
    Public Integer size{get;set;} 
    Public Integer noOfRecords{get; set;} 
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {                
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [select id,name,phone,email,AccountId,Primary_contact__c,Executive_Contact__c,status__c,Executive_Home_Phone__c, Unsubscribe_Notifications__c,
                     (select id,username from users) from contact where AccountId=:ids ]));
                setCon.setPageSize(size);  
                noOfRecords = setCon.getResultSize();
            }            
            return setCon;
        }
        set;
    }
    public List<Contact> getContacts(){
        return (List<Contact>) setCon.getRecords();
        
    }
    
    public PageReference editAccount(){
        hideAccount = true;
        showAccount = false;
        accDetails  = [Select id,Name,Phone,Billingaddress,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,website,annual_budget__c,
                       Membership_Expiration_Date__c,Membership_Start_Date__c,ParentId,Agency_Impact__c,Agency_Mission__c ,PT__c,FT__c,
                       Instagram__c,Facebook__c,twitter__c,Membership_Status__c
                       from Account 
                       where id=:[select AccountId from Contact where id=:accId ].AccountId ];
        System.debug('##'+accDetails);
        name = accDetails.Name;
        Phone =accDetails.Phone;
        
        BillingStreet=accDetails.BillingStreet;
        BillingCity= accDetails.BillingCity;
        BillingState=accDetails.BillingState;
        BillingCountry= accDetails.BillingCountry;
        BillingPostalCode =accDetails.BillingPostalCode ;
        website=accDetails.website;
        annualbudget=accDetails.annual_budget__c;
        memberexpDate=String.valueOf(accDetails.Membership_Expiration_Date__c);
        memberStatus=accDetails.Membership_Status__c;
        memberstartDate=String.valueof(accDetails.Membership_Start_Date__c);
        agencyImpact = accDetails.Agency_Impact__c;
        agencyMission=accDetails.Agency_Mission__c;
        if(accDetails.PT__c!=null)
            staffPT=String.valueof(accDetails.PT__c);
        system.debug('PT'+staffPT);
        if(accDetails.FT__c!=null)
            staffFT=String.valueof(accDetails.FT__c);
        insta=accDetails.Instagram__c;
        face=accDetails.Facebook__c;
        tweet=accDetails.twitter__c;
        ids=accDetails.id;
        //accLoc=accDetails.Parent.Community_URL_Prefix__c;
        return null;
    }
    
    public PageReference saveAccount(){
        hideAccount = false;
        showAccount = true;
        accDetails.Phone =Phone;
        accDetails.BillingStreet=BillingStreet;
        accDetails.BillingCity=BillingCity ;
        accDetails.BillingState= BillingState;
        accDetails.BillingCountry = BillingCountry;
        accDetails.BillingPostalCode = BillingPostalCode ;
        accDetails.website = website;
        accDetails.annual_budget__c = annualbudget;
        accDetails.Agency_Impact__c = agencyImpact;
        accDetails.Agency_Mission__c = agencyMission;
        if(String.isNotBlank(staffPT))
            accDetails.PT__c=Decimal.valueof(staffPT);
        else
            accDetails.PT__c=null;
        if(String.isNotBlank(staffFT))
            accDetails.FT__c=Decimal.valueof(staffFT);
        else
            accDetails.FT__c= null;
        accDetails.Instagram__c=insta;
        accDetails.Facebook__c=face;
        accDetails.twitter__c=tweet;
        system.debug('Before Updated'+accDetails);
        if(!Test.isRunningTest()) {
            update accDetails;
        }
        system.debug('Updated'+accDetails);
        return null;
    }
    public PageReference cancelAccount(){
        
        //accDetails = new Account();
        accDetails  = [Select id,Name,Phone,Billingaddress,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,website,annual_budget__c,
                       Membership_Expiration_Date__c,Membership_Status__c,Membership_Start_Date__c,ParentId,Agency_Impact__c,Agency_Mission__c ,PT__c,FT__c,
                       Instagram__c,Facebook__c,twitter__c 
                       from Account 
                       where id=:[select AccountId from Contact where id=:accId ].AccountId ];
        Phone =accDetails.Phone;
        
        BillingStreet=accDetails.BillingStreet;
        BillingCity= accDetails.BillingCity;
        BillingState=accDetails.BillingState;
        BillingCountry= accDetails.BillingCountry;
        BillingPostalCode =accDetails.BillingPostalCode ;
        website=accDetails.website;
        annualbudget=accDetails.annual_budget__c;
        memberexpDate=String.valueOf(accDetails.Membership_Expiration_Date__c);
        memberStatus=accDetails.Membership_Status__c;
        memberstartDate=String.valueof(accDetails.Membership_Start_Date__c);
        agencyImpact = accDetails.Agency_Impact__c;
        agencyMission=accDetails.Agency_Mission__c;
        staffPT=String.valueof(accDetails.PT__c);
        system.debug('PT'+staffPT);
        staffFT=String.valueof(accDetails.FT__c);
        insta=accDetails.Instagram__c;
        face=accDetails.Facebook__c;
        tweet=accDetails.twitter__c;
        hideAccount = false;
        showAccount = true;
        return null;
    }
    
}