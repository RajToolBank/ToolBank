public without sharing class FileController {

    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getFilesByAccount(String recordId) {
        Set<Id> cDocIds = new Set<Id>();
        for(ContentDocumentLink cdl :[SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
            cDocIds.add(cdl.ContentDocumentId);
        }
        return [SELECT Id, Title, Active__c FROM ContentVersion WHERE  ContentDocumentId  IN:cDocIds AND Title like '%_sponsored'];
    }

    @AuraEnabled
    public static void updateFileRecords(String updatedRecordsJSON){
        List<FileUpdateWrapper> updatedRecords = (List<FileUpdateWrapper>) JSON.deserialize(updatedRecordsJSON, List<FileUpdateWrapper>.class);
        List<ContentVersion> filesToUpdate = new List<ContentVersion>();
    
        // Iterate through the updated records and build the file records to update
        for (FileUpdateWrapper fileWrapper : updatedRecords) {
            // Retrieve the file record
            ContentVersion file = new ContentVersion();
            file.Id = fileWrapper.fileId;
            // Update the IsActive__c field
            file.Active__c = fileWrapper.isActive;
            
            // Add the file record to the list
            filesToUpdate.add(file);
        }

        // Update the file records
        if(filesToUpdate.size() >0)
            update filesToUpdate;
    }

    public class FileUpdateWrapper {
        @AuraEnabled
        public Id fileId;
        @AuraEnabled
        public Boolean isActive;
      }


}