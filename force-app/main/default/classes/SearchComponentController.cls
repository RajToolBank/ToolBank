public without sharing class SearchComponentController {
    @AuraEnabled
    public static List<sObject> search(String objectName, List<String> fields, String searchTerm){
        String searchKeyword = searchTerm + '*';
        String returningQuery = '';
        returningQuery = objectName+' ( Id, '+String.join(fields,',')+')';
        String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING '+returningQuery+' LIMIT 20';
        List<List<sObject>> searchRecords = new List<List<sObject>>();
        List<SObject> sobjList = new List<SObject>();
        if(String.isBlank(searchTerm)){
            String soqlQuery = 'SELECT '+ String.join(fields,',')+', Id, LastViewedDate FROM '+objectName+' ORDER BY LastViewedDate DESC LIMIT 5';
            system.debug(soqlQuery);
            sobjList = Database.query( soqlQuery );
            searchRecords.add(sobjList);
        }else{
            searchRecords = Search.Query(Query);
        }

        system.debug(searchRecords.get(0));
        return searchRecords.get(0);
    }

    @AuraEnabled
    public static sObject getRecentlyCreatedRecord(String recordId, List<String> fields, String objectName){
        sObject createdRecord;
        try {
            String query = 'SELECT Id, '+String.join(fields,',')+' FROM '+objectName+' WHERE Id = \''+recordId+'\'';
            List<SObject> sobjList = Database.query( query );
            createdRecord = sobjList.get(0);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return createdRecord;
    }

    @AuraEnabled
    public static List<sObject> search2(String objectName, List<String> fields, String searchTerm, String parentId){
        String searchKeyword = '%'+ searchTerm + '%';
        String query = 'SELECT Id, '+String.join(fields,',')+' FROM '+objectName+' WHERE Name like \''+searchKeyword+'\'';
        if(String.isNotBlank(parentId) && 'Contact'.equalsIgnoreCase(objectName))
            query =  query + ' AND ( AccountId = \''+parentId+'\' OR npsp__Primary_Affiliation__c = \''+parentId+'\' )';

        String agency = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Member_Agency').getRecordTypeId();
        if('Account'.equalsIgnoreCase(objectName))
            query =  query + ' AND RecordTypeId = \''+agency+'\' AND parentId= \''+parentId+'\'';

        List<SObject> sobjList = Database.query( query );
        return sobjList;
    }


    @AuraEnabled
    public static List<sObject> search3(String objectName, List<String> fields, String searchTerm, String parentId){

        List<SObject> sobjList = new List<SObject>();
        User currentUser = [SELECT Id,Name,profile.name,contactId,contact.AccountId,contact.npsp__Primary_Affiliation__c FROM User WHERE Id=: UserInfo.getUserId()];
        String searchKeyword = '%'+ searchTerm + '%';
        String query = 'SELECT Id, ';
        if('TB Members Plus'.equalsIgnoreCase(currentUser.profile.Name) || 'TB Members'.equalsIgnoreCase(currentUser.profile.Name)){

            List<Id> accIdList = new List<Id>();
            for(npe5__Affiliation__c affCon: [SELECT Id,npe5__Organization__c FROM npe5__Affiliation__c WHERE npe5__Contact__c =: currentUser.contactId AND npe5__Status__c = 'Current' ]){
                accIdList.add(affCon.npe5__Organization__c);
            } 

            if('Account'.equalsIgnoreCase(objectName)){
                query += String.join(fields,',')+' FROM '+objectName+' WHERE Name like \''+searchKeyword+'\'';
                String agency = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Member_Agency').getRecordTypeId();
                query =  query + ' AND RecordTypeId = \''+agency+ '\' AND Id IN: accIdList';

                sobjList = Database.query( query );
            }

            if(String.isNotBlank(parentId) && 'Contact'.equalsIgnoreCase(objectName)){
                query += 'npe5__Contact__r.Name,npe5__Contact__r.Email FROM npe5__Affiliation__c WHERE npe5__Contact__r.Name like \''+searchKeyword+'\'';
                query += ' AND npe5__Status__c = \'Current\' AND npe5__Organization__c = \''+parentId+'\'';
        
                for(npe5__Affiliation__c affCon: (List<npe5__Affiliation__c>)Database.query( query )){

                    sobjList.add(affCon.npe5__Contact__r);
                }
            }



        }else{

            if('Account'.equalsIgnoreCase(objectName)){
                query += String.join(fields,',')+' FROM '+objectName+' WHERE Name like \''+searchKeyword+'\'';
                String agency = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Member_Agency').getRecordTypeId();
                query =  query + ' AND RecordTypeId = \''+agency+'\' AND parentId= \''+parentId+'\''; 

                sobjList = Database.query( query );
            }

            if(String.isNotBlank(parentId) && 'Contact'.equalsIgnoreCase(objectName)){

                query += 'npe5__Contact__r.Name,npe5__Contact__r.Email FROM npe5__Affiliation__c WHERE npe5__Contact__r.Name like \''+searchKeyword+'\'';
                query += ' AND npe5__Status__c = \'Current\' AND npe5__Organization__c = \''+parentId+'\'';

                for(npe5__Affiliation__c affCon: (List<npe5__Affiliation__c>)Database.query( query )){

                    sobjList.add(affCon.npe5__Contact__r);
                }
            }

        }

//        List<SObject> sobjList = Database.query( query );
        return sobjList;
    }

    @AuraEnabled
    public static List<sObject> search4(String searchTerm, String currentAffiliate){
        searchTerm = '%'+searchTerm+'%';
        list<Account> accList = new List<Account>();
        for(Affiliate_Account__c afa : [SELECT Id,Affiliate__r.id,Affiliate__r.Name FROM Affiliate_Account__c WHERE Affiliate__r.Name like: searchTerm AND Affiliate__r.RecordType.Name='Affiliate' AND Affiliate__c !=: currentAffiliate AND User__c =: UserInfo.getUserId()]){
            accList.add(afa.Affiliate__r);
        }
        // if(accList.size() == 0){
        //     return [SELECT Id, Name FROM Account WHERE Name like: searchTerm AND RecordType.Name='Affiliate' AND Id !=: currentAffiliate];
        // }
        return accList;
    }

}