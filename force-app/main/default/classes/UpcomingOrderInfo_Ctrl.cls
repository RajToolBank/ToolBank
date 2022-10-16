public class UpcomingOrderInfo_Ctrl {
    
    public List<OrderItem> ol {get;set;}
    public List<order> ordr {get;set;}
    public string ordrId{get;set;}
    public account accDetails{set;get;}
    
    public List<Network> listOfNetwork {get; set;}
    public Domain dom {get;set;}
    public String finalURL {get;set;}
    public List<User> licen {get;set;}
    
    public upcomingOrderInfo_Ctrl() {
        Contact con = [Select contactId,contact.AccountId,contact.npsp__Primary_Affiliation__c from user where id=:userinfo.getuserid()].Contact;
        String accId;
        if(con.npsp__Primary_Affiliation__c != Null)
            accId = con.npsp__Primary_Affiliation__c;
        else accId = con.AccountId;
        System.debug(accId );
        accDetails  = [Select id,Name,Phone,Billingaddress,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,website,annual_budget__c,ParentId
                       from Account 
                       where id=:accId ];
        
        ordr =  [select id,Name,ordernumber,EffectiveDate,BillToContactId,TotalAmount,AccountId,Total_Amount__c,Number_Of_Projects__c  
                 from order where EffectiveDate >= Today and AccountId  = :accDetails.Id
                 limit 3];   
        
       /* listOfNetwork = new list<Network>();
        String urlpath ;
        listOfNetwork = [SELECT Name, UrlPathPrefix, Status FROM Network where Name = 'Agency Member' and status='live' limit 1];
        licen = [SELECT Profile.UserLicense.Name FROM User where id=:userinfo.getuserid()];
        List<Domain> domList= [select domain from domain];
        dom = domList[0]; //WHERE domain like '%NewAtlanta'];
        system.debug(domList);
        if(!listOfNetwork.isEmpty()) {
            for(Network n : listOfNetwork) {
                for(User l : licen) {
                    if(n.name.contains('Agency') && l.Profile.UserLicense.name == 'Customer Community'){
                        urlpath = n.UrlPathPrefix;
                        finalURL = 'https://'+dom.domain+'/'+urlpath;
                    }
                } 
            }
        }*/
        finalURL = label.CommunitySiteURL;
        System.debug('Final'+finalURL);
    }
    
    public Pagereference navigatePage() {
        PageReference pref; 
        System.debug(ordrId);
        try {
            pref = new PageReference(finalURL+'/s/detail/'+ordrId);
            pref.setredirect(true);
            
        } catch(exception e){
            system.debug(e);
        }
        return pref; 
    }
    public Pagereference viewAllPage(){
        PageReference pref;
        pref = new PageReference(finalURL+'/s/recordlist/Order/Recent');
        return pref; 
    }
}