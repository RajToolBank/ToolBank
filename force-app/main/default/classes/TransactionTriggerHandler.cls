public with sharing class TransactionTriggerHandler {

    static final String  DONATION='012020000000L9zAAE', DAMAGED='012020000000L9QAAU',BACK_IN_SERVICE='012020000000LJzAAM',
            INTERNAL_AUDIT='012020000000L9fAAE',LOST='012020000000L9kAAE',PURCHASED='012020000000L9RAAU',
            RETIRE='012020000000L9aAAE',RE_TURN='012020000000L9uAAE',OUT='012020000000LJuAAM',OUT_OF_SERVICE='012020000000LJVAA2';
            
    public static void updqteQuantity(List<Transaction__c> transList){

        for (Transaction__c tran : transList) {
            String RecordTypeId = tran.RecordTypeId;
            String subType = tran.sub_type__c;
            if(BACK_IN_SERVICE.equals(RecordTypeId)){ // Back in service
                tran.quantity__c = (-tran.quantity__c);
            }
        }
    }
    
    public static void transaction(List<Transaction__c> transList) {
        
        Map<Id, List<Transaction__c>> InvIdToTranMap = new Map<Id, List<Transaction__c>>();
        for(Transaction__c tran: transList){

            if(tran.inventory__c != null){
                if(!InvIdToTranMap.containsKey(tran.inventory__c))
                    InvIdToTranMap.put(tran.inventory__c, new List<Transaction__c>());
                
                    InvIdToTranMap.get(tran.inventory__c).add(tran);
            }
        }
       
        
        List<Asset> assestListToUpdate = new List<Asset>();
        for(Asset asset: [SELECT Id,Total_Stock_Historical__c,quantity FROM Asset WHERE ID IN: InvIdToTranMap.keyset()]){
            
            Decimal his=0,total=0,curr=0,shelf=0;
            

            for(Transaction__c tran: InvIdToTranMap.get(asset.Id)){
                Decimal quantity = tran.quantity__c;
                quantity = quantity <0?(-quantity):quantity;

              /*  if(oldmap != Null && oldmap.containsKey(tran.id)){
                    Decimal oldQuantity = oldmap.get(tran.id).quantity__c;
                    oldQuantity = oldQuantity <0?(-oldQuantity):oldQuantity;
                    quantity = quantity - oldQuantity;
                }*/
                system.System.debug('quantity :: '+quantity + 'his :: '+his + 'total :: '+total );
                String RecordTypeId = tran.RecordTypeId;
                if(DONATION.equals(RecordTypeId)){ // Donation
                    his += quantity;
                    total += quantity;
                }else if(PURCHASED.equals(RecordTypeId)){ // purchased
                    his += quantity;
                    total += quantity;
                }else if(LOST.equals(RecordTypeId)){ // Lost
                    total -= quantity;
                    
                }else if(RETIRE.equals(RecordTypeId)){ // Retire
                    total -= quantity;
                }else if(INTERNAL_AUDIT.equals(RecordTypeId)){ // Inventory Audit
                    
                    if('Increase'.equals(tran.sub_type__c)){
                        total += quantity;
                    }else if('Decrease'.equals(tran.sub_type__c)){
                        total += quantity;
                    }
                    
                }
            }
            
            asset.quantity = (asset.quantity != null?asset.quantity:0) +total;
            asset.Total_Stock_Historical__c = (asset.Total_Stock_Historical__c != null?asset.Total_Stock_Historical__c:0) +his;
            
           
            assestListToUpdate.add(asset);

        }

        if(!assestListToUpdate.isEmpty())
            update assestListToUpdate;

    }
}