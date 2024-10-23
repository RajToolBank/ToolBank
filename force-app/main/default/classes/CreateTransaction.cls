public without sharing class CreateTransaction {
    

    @AuraEnabled(cacheable = true)
    public static List<PickListOption> getRecordType(){
        Schema.DescribeSObjectResult d = Schema.SObjectType.Transaction__c; 
        Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();

        List<PickListOption> recordTypeOptionList = new list<PickListOption>();
        for(Schema.RecordTypeInfo recInfo: rtMapById.values()){

            if(recInfo.isActive() && recInfo.getName() != 'Master' && recInfo.getName() != 'Fulfilled' && recInfo.getName() != 'Returned'){
                PickListOption rectype = new PickListOption();
                rectype.label = recInfo.getName();
                rectype.value = recInfo.getRecordTypeId();
                System.debug(recInfo);
                recordTypeOptionList.add(rectype);
            }
        }

        return recordTypeOptionList;
    }

    @AuraEnabled
    public static String createTransaction(String inventoryId, String recordTypeId, String subType, Integer qty, String note, String affiliateId){
        String recordTypeName = [Select Id, Name, DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1].DeveloperName;
        Asset inv1 = [SELECT id, accountId,On_Shelf_Quantity_F__c,product2Id FROM Asset WHERE Id =: inventoryId];
        if(qty > 0) {
            if(recordTypeName == 'Out_Of_Service' || recordTypeName == 'Transfer' || subType == 'Decrease' || subType == 'Lost from Inventory' || recordTypeName == 'Retired') {
                if(qty <= inv1.On_Shelf_Quantity_F__c) {
                    if(recordTypeName == 'Transfer') {
                        Asset inv = [SELECT Id FROM Asset WHERE AccountId =: affiliateId AND product2Id =:inv1.product2Id];
                        Transaction__c trans = new Transaction__c();
                        trans.sub_type__c = 'Decrease';
                        trans.inventory__c = inventoryId;
                        trans.Transfer_From__c = inv1.accountId;
                        trans.Transfer_To__c = affiliateId;
                        trans.recordTypeId = recordTypeId;
                        trans.quantity__c = qty;
                        trans.note__c = note;
                        Transaction__c trans2 = new Transaction__c();
                        trans2.sub_type__c = 'Increase';
                        trans2.inventory__c = inv.Id;
                        trans2.Transfer_From__c = inv1.accountId;
                        trans2.Transfer_To__c = affiliateId;
                        trans2.recordTypeId = recordTypeId;
                        trans2.quantity__c = qty;
                        trans2.note__c = note;
                        insert new list<Transaction__c>{trans,trans2};
                            } else {
                                Transaction__c trans = new Transaction__c();
                                trans.sub_type__c = subType;
                                trans.inventory__c = inventoryId;
                                trans.recordTypeId = recordTypeId;
                                trans.quantity__c = qty;
                                trans.note__c = note;
                                insert trans;
                            }
                } else {
                    return 'The Quantity entered exceeds the On Shelf Quantity for this tool';
                }
            } else {
                Transaction__c trans = new Transaction__c();
                trans.sub_type__c = subType;
                trans.inventory__c = inventoryId;
                trans.recordTypeId = recordTypeId;
                trans.quantity__c = qty;
                trans.note__c = note;
                insert trans;
            }
        } else {
            return 'The Quantity entered must be greater than 0';
        }
        return 'Successfull';
    }

    @AuraEnabled
    public static List<PickListOption> getValues(String objectType, String recordTypeId, String fieldName) {
        
        // Create the endpoint dynamically for your og
        Api_Credentials__mdt api = Api_Credentials__mdt.getInstance('Salesforce');
        String endpoint = api.endpoint__c+'/services';   
        
        String tokenEndpoint = endpoint+'/oauth2/token?';
        tokenEndpoint += 'grant_type=password&client_id='+api.client_id__c
                        +'&client_secret='+api.Clinet_Secret__c
                        +'&username='+api.username__c
                        +'&password='+api.password__c;
        HttpRequest tokenReq = new HttpRequest();
        tokenReq.setEndpoint(tokenEndpoint);
        tokenReq.setMethod('POST');
        Http tokenHttp = new Http();

        HTTPResponse tokenRes =tokenHttp.send(tokenReq);
        Map<String, object> token = (Map<String, object>)JSON.deserializeUntyped(tokenRes.getBody());
        String access_token = (String)token.get('access_token');

        endpoint += '/data/'+api.version__c;
        endpoint += '/ui-api/object-info/' + objectType + '/picklist-values/' + recordTypeId + '/' + fieldName;
        
        
        EncodingUtil.urlEncode(endpoint,'UTF-8');
        
        // Call the API in order to get the values 
        HttpRequest req = new HttpRequest();
        
        // Since, we can not use the UserInfo.getSessionId() method here, I am using a Visualforce page in order
        // to extract the session id which we can use for making API calls
        
        req.setHeader('Authorization', 'Bearer ' + access_token);//'00D020000008pmO!AREAQC2xvIy.8Fj3ZSuilgG9Gi48WrFqvOlut5hXEyI0wegmSyZpZYSSBrSBMPt9WhVZKMm3vXSlXVTNNWDFe3dIobocO5ZZ');
        req.setHeader('Accept', 'application/json '); 
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        Map<String, String> result = new Map<String,String>();
        Map<String, List<String>> mapControllingWithDependentList = new Map<String,List<String>>();
        Map<Object, String> mapControllingValueWithIndex = new Map<Object,String>();
        Map<String, List<String>> mapPicklistValues = new Map<String,List<String>>();
        
        List<PickListOption> subtypeList = new List<PickListOption>();
        if( res.getStatus() == 'OK' && res.getStatusCode() == 200 ) {
            
            Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped( res.getBody() );
            
            System.debug( ' Response Body : ' + root.get('values'));
            for(Object obj: (List<Object>)root.get('values'))   {
                PickListOption sub = new PickListOption();
                Map<String,object> temp = (Map<String,object>)obj;
                sub.label = (String)temp.get('label');
                sub.value = (String)temp.get('value');
                if(sub.value != 'Lost - Return') {
                    subtypeList.add(sub);
                }
            }
        }
        return subtypeList;
        
    }

    @AuraEnabled
    public static String createBulkTransaction(String toolList, String recordTypeId, String subType, String affiliateId){
        System.debug('toolList :: '+toolList);
        List<Object> invItemList = (List<Object>) json.deserializeUntyped(toolList);
        String recordTypeName = [Select Id, Name, DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1].DeveloperName;
        
        List<String> productIdList = new List<String>();
        Map<String,Asset> productIdToAssetMap = new Map<String, Asset>();
        for(Object obj: invItemList){
            System.debug(obj);
            Map<String, Object> tool = (Map<String, Object>)obj;
            productIdList.add((String)tool.get('Product2Id'));
        }
        for(Asset asset: [SELECT Id, Product2Id FROM Asset WHERE AccountId =: affiliateId AND product2Id IN: productIdList]){
            productIdToAssetMap.put(asset.product2Id,asset);
        }

        list<Transaction__c> transactionToInsert = new List<Transaction__c>();
        for(Object obj: invItemList){
            Map<String, Object> tool = (Map<String, Object>)obj;
            if(recordTypeName == 'Transfer') {
                
                Transaction__c trans = new Transaction__c();
                trans.sub_type__c = 'Decrease';
                trans.inventory__c = (String)tool.get('InventoryId');
                trans.recordTypeId = recordTypeId;
                trans.quantity__c = Decimal.valueOf((String)tool.get('Quantity'));
                trans.note__c = (String)tool.get('Note');
                Transaction__c trans2 = new Transaction__c();
                trans2.sub_type__c = 'Increase';
                trans2.inventory__c = productIdToAssetMap.get((String)tool.get('Product2Id')).Id;
                trans2.recordTypeId = recordTypeId;
                trans2.quantity__c = Decimal.valueOf((String)tool.get('Quantity'));
                trans2.note__c = (String)tool.get('Note');
                transactionToInsert.add(trans);
                transactionToInsert.add(trans2);
            } else {
                    Transaction__c trans = new Transaction__c();
                    trans.sub_type__c = subType;
                    trans.inventory__c = (String)tool.get('InventoryId');
                    trans.recordTypeId = recordTypeId;
                    trans.quantity__c = Decimal.valueOf((String)tool.get('Quantity'));
                    trans.note__c = (String)tool.get('Note');
                    trans.donating_company__c = (String)tool.get('DonationCompany');
                    transactionToInsert.add(trans);
                }
        }

        if(transactionToInsert.size() >0){
            insert transactionToInsert;
        }

        return 'Success';
    }

    public class PickListOption{
        @AuraEnabled
        public String value;
        @AuraEnabled
        public string label;
    }
}