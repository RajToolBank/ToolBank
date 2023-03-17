public without Sharing class PlaceOrderController {
    
    @AuraEnabled(cacheable = true)
    public static Boolean getFlag(){
        Contact con = [SELECT Id, AccountId,Contact.Account.parentId,contact.npsp__Primary_Affiliation__c,contact.npsp__Primary_Affiliation__r.Flagged__c, Contact.Account.Flagged__c FROM User WHERE Id =: UserInfo.getUserId()].Contact;
        Boolean flagged = false;
        if(con != null && con.npsp__Primary_Affiliation__c != Null)
            flagged = con.npsp__Primary_Affiliation__r.Flagged__c;
        else if(con != null) flagged = con.Account.Flagged__c;
        return flagged;
    }
    
    @AuraEnabled(cacheable = true)
    public static string accid(){
        Contact con = [SELECT Id,AccountId, Contact.Account.parentId,contact.npsp__Primary_Affiliation__r.parentId FROM User WHERE Id =: UserInfo.getUserId()].Contact;
        String accid;
        if(con != null &&  con.npsp__Primary_Affiliation__c != Null)
            accid = con.npsp__Primary_Affiliation__r.parentId;
        else if(con != null) accid = con.Account.parentId;

        if(String.isBlank(accId)){
            List<Affiliate_Account__c> aff = [SELECT Id, Affiliate__c,Affiliate__r.Name FROM Affiliate_Account__c WHERE User__c =:UserInfo.getUserId()];
            if(aff != null && aff.size() >0 && aff.size() == 1)
                accid = aff[0].Affiliate__c;
        }
        return accId;
    }
    
    @AuraEnabled//(cacheable = true)
    public static UserClass getAgencyContact(String recordId){
        User user = [SELECT Id,contactId,UserType, Contact.Email,contact.npsp__Primary_Affiliation__c, contact.npsp__Primary_Affiliation__r.name, Contact.AccountId,Contact.Name,contact.Account.Name FROM User WHERE Id =: UserInfo.getUserId()];
        
        UserClass userCus = new UserClass();
        userCus.Id = user.Id;
        userCus.UserType = user.UserType; 
        
        if(String.isNotBlank(recordId) && recordId.startsWith('001')){
            Account acc = [SELECT Id,Name FROM Account WHERE Id=:recordId];
            List<npe5__Affiliation__c> affCon = [SELECT Id,npe5__Contact__c,npe5__Contact__r.Name,npe5__Contact__r.Email FROM npe5__Affiliation__c WHERE npe5__Organization__c =: acc.Id AND npe5__Contact__r.Primary_Contact__c = true LIMIT 1];
            if(affCon != null && affCon.size() >0){
                userCus.contactId = affCon[0].npe5__Contact__c;
                userCus.contactEmail = affCon[0].npe5__Contact__r.Email;
                userCus.contactName = affCon[0].npe5__Contact__r.Name;
            }
            userCus.contactAccountId = acc.Id; 
            userCus.contactAccountName = acc.Name; 
        }else if(user.contactId != null){
            userCus.contactId = user.contactId;
            userCus.contactEmail = user.Contact.Email;
            userCus.contactName = user.Contact.Name; 
            if(user.contact.npsp__Primary_Affiliation__c != Null){
                userCus.contactAccountId = user.contact.npsp__Primary_Affiliation__c;
                userCus.contactAccountName = user.contact.npsp__Primary_Affiliation__r.name;
            }else{
                userCus.contactAccountId = user.Contact.AccountId; 
                userCus.contactAccountName = user.contact.Account.Name; 
            }
        } 
        return userCus;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Account> getAffiliate(){
        List<Account> accList = new List<Account>();
        for(Affiliate_Account__c aff: [SELECT Id, Affiliate__c,Affiliate__r.Name FROM Affiliate_Account__c WHERE User__c =:UserInfo.getUserId()]){
            accList.add(aff.Affiliate__r);
        }
        
        if(accList != Null && accList.size() >0)
            return accList;
        else return  [SELECT Id,Name FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId()];
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Tool> returnAssets(String searchString,String affiliateId){
        try {
            Contact con = [SELECT Id, AccountId,Contact.Account.parentId,contact.npsp__Primary_Affiliation__r.parentId FROM User WHERE Id =: UserInfo.getUserId()].Contact;
            String accid;
            if(con != Null && con.npsp__Primary_Affiliation__c != Null)
                accid = con.npsp__Primary_Affiliation__r.parentId;
            else if(con != Null) accid = con.Account.parentId;
            List<Asset> assetList;
            List<Tool> tools = new List<Tool>();
            if(String.isNotBlank(affiliateId)){
                accId = affiliateId;
            }
            if(String.isBlank(searchString)){
                assetList=  [SELECT Id,
                             Affiliate_Handling_Fee__c,
                             Product2.Description,
                             Product2Id,
                             Product2.spanish_name__c,
                             Product2.Job_Type__c,
                             Product2.Highlights__c,
                             Product2.Name,
                             Product2.productCode,
                             Product2.Sub_Category__c,
                             Product2.Family,
                             Product2.Product_Image__c,
                             Product2.Tool_Note__c,
                             price 
                             FROM Asset
                             WHERE AccountId =: accid
                             AND Unlisted_Item__c = false
                             AND Product2.type__c = 'Tool'
                             AND (Quantity != Null 
                                  AND Quantity != 0)];
                
            }else {
                searchString = '%'+searchString+'%';
                assetList=  [SELECT Id,Affiliate_Handling_Fee__c,
                             Product2Id,
                             Product2.spanish_name__c,
                             Product2.Description,
                             Product2.Job_Type__c,
                             Product2.Highlights__c,
                             Product2.Name,
                             Product2.productCode,
                             Product2.Sub_Category__c,
                             Product2.Family,
                             Product2.Product_Image__c,
                             Product2.Tool_Note__c,
                             price 
                             FROM Asset 
                             WHERE AccountId =: accid 
                             AND Unlisted_Item__c = false
                             AND (Product2.Name like: searchString 
                                  OR Product2.spanish_name__c like: searchString
                                  OR Product2.Family like: searchString 
                                  OR Product2.sub_category__c like: searchString 
                                  OR Product2.productCode like: searchString 
                                  OR Product2.Tool_Note__c like: searchString )
                             AND Product2.type__c = 'Tool'
                             AND (Quantity != Null 
                                  AND Quantity != 0)];
                
            }
            Map<Id, Asset> productIdAssetMap = new Map<Id, Asset>();
            for(Asset asset: assetList){
                productIdAssetMap.put(asset.Product2Id, asset);
            }
            
            for(PriceBookEntry pbe: [SELECT Id,Product2.spanish_name__c,product2Id,unitPrice 
                                     FROM PriceBookEntry 
                                     WHERE Product2Id IN: productIdAssetMap.keyset() 
                                     AND Product2.type__c = 'Tool'
                                     ORDER BY product2.Sort_Category__c,product2.Family, product2.sub_category__c]){
                                         Tool tool = new Tool();
                                         tool.asset = productIdAssetMap.get(pbe.product2Id);
                                         tool.pbe = pbe;
                                         tool.hanlingFee = (pbe.unitPrice*tool.asset.Affiliate_Handling_Fee__c/100).setScale(2);
                                         tool.note = 'Note: '+productIdAssetMap.get(pbe.product2Id).Product2.Tool_Note__c
                                         +'Description: '+productIdAssetMap.get(pbe.product2Id).Product2.Description;
                                         tools.add(tool);
                                     }
            
            return tools;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> zipCodes(){
        try {
            List<String> zipcodes = new List<String>();
            for(Zip_Code__c zip : [SELECT name FROM Zip_Code__c]){
                zipcodes.add(zip.name);
            }
            return zipcodes;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<HelpText> getPicklistValuesApex(String field_name){
        List<HelpText> picklistValues = new List<HelpText>();
        Map<String, Help_Text__c> helpTextMap = Help_Text__c.getAll();
        String[] types = new String[]{'Order'};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeFieldResult fieldResult = results[0].fields.getMap().get(field_name).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
            HelpText helpText = new HelpText();
            helpText.value = pickListVal.getValue();
            helpText.label = pickListVal.getLabel();
            helpText.helpText = helpTextMap.containsKey(pickListVal.getValue())?helpTextMap.get(pickListVal.getValue()).Help_Text__c:'';
			picklistValues.add(HelpText);
		} 
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static string placeOrder(String Order){
        Map<String,object> orderDetail = (map<string,object>)JSON.deserializeUntyped(order);
        Map<String,object> orderObj = (Map<String,object>)orderDetail.get('order');
        List<Object> toolObj = (List<Object>)orderDetail.get('tools');
        
        Order ord = new Order();
        try{
            ord.status = 'Unconfirmed';
            ord.pricebook2Id = label.pricebookid;
            ord.name = (String)orderObj.get('name');
            String zipCodes = (String)orderObj.get('zip');
            ord.Serving_50_of_Low_Income_People__c = (String)orderObj.get('serv');
            List<Object> proVenueList = (List<Object>)orderObj.get('proVenue');
            List<Object> proTypeList = (List<Object>)orderObj.get('proType');
            List<Object> impactAreaList = (List<Object>)orderObj.get('impactArea');
            String proVenue='';
            for(Object obj: proVenueList){
                proVenue +=(String)obj+';';
            }
            String proType='';
            for(Object obj: proTypeList){
                proType += (String)obj+';';
            }
            String impactArea='';
            for(Object obj: impactAreaList){
                impactArea += (String)obj+';';
            }
            ord.Project_Venue__c = proVenue;
            ord.Project_Type__c = proType;
            ord.Areas_Of_Impact__c = impactArea;
            ord.AccountId = (String)orderObj.get('accountId');
            ord.BillToContactId = (String)orderObj.get('contactId');
            ord.Desired_Pickup_Date__c = Date.valueOf((String)orderObj.get('pickdate'));
            ord.Desired_Pickup_Time__c = (String)orderObj.get('pickTime');
            ord.EndDate = Date.valueOf((String)orderObj.get('retDate'));
            ord.Schedule_Return_Date__c = Date.valueOf((String)orderObj.get('retDate'));
            ord.Requested_Borrowing_Period__c = (String)orderObj.get('duration');
            ord.Corporation_Name__c = (String)orderObj.get('corpname');
            if((String)orderObj.get('home') != null)
                ord.If_Yes_How_Many_Homes__c = Decimal.valueOf((String)orderObj.get('home'));
            
            if((String)orderObj.get('numAttend') != null)
                ord.Number_of_Attendees__c = Decimal.valueOf((String)orderObj.get('numAttend'));
            
            ord.EffectiveDate =ord.Desired_Pickup_Date__c;
            
            if((String)orderObj.get('pickTime') != Null){
                Time pickTime;
                String timeString = (String)orderObj.get('pickTime');
                if(timeString.containsIgnoreCase('am')){
                    timeString = timeString.replace('AM','');
                    list<String> temp = timeString.split(':');
                    Integer hour = temp != Null && temp.size() >0?Integer.valueOf(temp[0].trim()):0;
                    Integer min = temp != Null && temp.size() >=1?Integer.valueOf(temp[1].trim()):0;
                    pickTime = Time.newInstance(hour,min,0,0);
                }else{
                    timeString = timeString.replace('PM','');
                    list<String> temp = timeString.split(':');
                    Integer hour = temp != Null && temp.size() >0?Integer.valueOf(temp[0].trim()):0;
                    Integer min = temp != Null && temp.size() >=1?Integer.valueOf(temp[1].trim()):0;
                    if(hour != 12)
                    pickTime = Time.newInstance(hour+12,min,0,0);
                    else pickTime = Time.newInstance(hour,min,0,0);
                }
                ord.Scheduled_Pickup_Time__c = pickTime;
            }

            ord.Affiliate__c = (String)orderObj.get('affiliateid');
            String peopleserved= (String)orderObj.get('peopledirectlyserved');
            String projectNumber= (String)orderObj.get('numberProject');
            String avgHr= (String)orderObj.get('onsitehours');
            String voluNumber= (String)orderObj.get('volunteersnumber');
            String staff= (String)orderObj.get('staff');
            String totalVol= (String)orderObj.get('projectVolunteerHr');
            String peopleimpact= (String)orderObj.get('peopleImImpacted');
            ord.Volunteer_Source__c = (String)orderObj.get('volunteersource');
            
            ord.People_Directly_Served__c = String.isBlank(peopleserved)?null: Decimal.valueOf(peopleserved);
            ord.Number_Of_Projects__c = String.isBlank(projectNumber)?null: Decimal.valueOf(projectNumber);
            ord.Hours_Average_Volunteer_is_on_Site__c = String.isBlank(avgHr)?null: Decimal.valueOf(avgHr);
            ord.Number_of_Volunteers__c = String.isBlank(voluNumber)?null: Decimal.valueOf(voluNumber);
            ord.People_Indirectly_Impacted__c = String.isBlank(peopleimpact)?null: Decimal.valueOf(peopleimpact);
            ord.Staff_on_this_Project__c = String.isBlank(staff)?null: Decimal.valueOf(staff);
            ord.Total_Project_Volunteer_Hours__c = String.isBlank(totalVol)?null: Decimal.valueOf(totalVol);

            ByPassValidations.ordStatusValidation = true;
            insert ord;
            
            if(zipCodes != null){
                list<String> zipCodeList =  zipCodes.split(',');
                if(zipCodeList != null && zipCodeList.size() >0){
                    list<Order_Zip_Code__c> ordZipCodes = new List<Order_Zip_Code__c>();
                    for(String zip: zipCodeList){
                        system.debug(zip);
                        if(!String.isblank(zip)){
                            Order_Zip_Code__c ordZip = new Order_Zip_Code__c();
                            ordZip.Order__c = ord.id;
                            ordZip.name = zip;
                            ordZip.Zip_Code__r = new Zip_Code__c(Zip_Code__c = zip);
                            ordZipCodes.add(ordZip); 
                        }
                    }
                    
                    if(!ordZipCodes.isEmpty())
                        insert ordZipCodes;
                }
            }
            
            List<OrderItem> orderItemList = new List<OrderItem>();
            for(Object tool:toolObj){
                Map<String, Object> product = ( Map<String, Object>)tool;
                OrderItem item = new OrderItem();
                item.quantity = Decimal.valueOf((String)product.get('quantity'));
                item.unitPrice = Decimal.valueOf((String)product.get('retailPrice'));
                item.Affiliate_Handling_Fee__c = Decimal.valueOf((String)product.get('affiliatefee'));
                item.Requested_Borrowing_Period__c = (String)orderObj.get('duration');
                item.PriceBookEntryId = (String)product.get('pbeid');
                item.Inventory_Tool__c = (String)product.get('assetId');
                item.orderId = ord.id;
                item.Schedule_Pick_Date__c = Date.valueOf((String)orderObj.get('pickdate'));
                item.Schedule_Return_Date__c = Date.valueOf((String)orderObj.get('retDate'));
                item.status__c= 'Unconfirmed';
                orderItemList.add(item);
            }
            
            
            
            if(!orderItemList.isEmpty())
                insert orderItemList;
            
            if(ord != Null)
                LowestQuantityCalculateClasss.lowestQuantityOrder2(new List<order>{ord});
        }catch(Exception e){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { 'rajsfdcproject@gmail.com' };
            message.subject = 'Order place error';
            message.plainTextBody = e.getMessage() +'\n'+e.getStackTraceString()+'\n'+e.getLineNumber()+'\n'+e.getCause();
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            //throw new AuraHandledException(e.getMessage());
        }
        return '/'+ord.id;
    }
    
    public class Tool{
        @AuraEnabled
        public Asset asset;
        @AuraEnabled
        public PriceBookEntry pbe;
        @AuraEnabled
        public Decimal hanlingFee;
        @AuraEnabled
        public String note;
    }

    public class HelpText{
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String helpText;
    }

    public class UserClass{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String userType;
        @AuraEnabled
        public String contactEmail;
        @AuraEnabled
        public String contactAccountId;
        @AuraEnabled
        public String contactName;
        @AuraEnabled
        public String contactAccountName;
    }
    
}