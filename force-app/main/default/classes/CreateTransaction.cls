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
    public static String createTransaction(String inventoryId, String recordTypeId, String subType, Integer qty, String note){

       
        Transaction__c trans = new Transaction__c();
        trans.inventory__c = inventoryId;
        trans.recordTypeId = recordTypeId;
        trans.quantity__c = qty;
        trans.sub_type__c = subType;
        trans.note__c = note;

        insert trans;

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
                subtypeList.add(sub);
            }
        }
        return subtypeList;
        
    }

    public class PickListOption{
        @AuraEnabled
        public String value;
        @AuraEnabled
        public string label;
    }
}