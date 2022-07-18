public with sharing class AdditionalChargesController {
    
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(){

        return [SELECT Id,unitPrice,product2Id,Product2.Type__c,Product2.family,Product2.Name,Product2.Tool_Note__c FROM PricebookEntry WHERE Product2.Type__c ='Additional Charges' and Product2.isActive= true];
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getAdditionProducts(String orderid){

        return [SELECT Id,unitPrice,OrderId,Description,product2Id,PricebookEntryId,Product2.Type__c,Product2.family,Product2.Name,Product2.Tool_Note__c FROM OrderItem WHERE OrderId=:orderid AND Product2.Type__c ='Additional Charges'];
    }

    @AuraEnabled
    public static List<OrderItem> addProducts(String orderItems){
       // try {
            system.debug(orderItems);
            list<OrderItem> orderItemList = new List<orderItem>();
            List<Object> ordItemList = (List<Object>) json.deserializeUntyped(orderItems);
            String orderid;
            for(Object obj: ordItemList){
                Map<String, object> item = (Map<String, object>)obj;
                String itemId = (string)item.get('Id');
                system.debug(item.get('OrderId'));
                if(orderid == Null)
                    orderid = (string)item.get('OrderId');
                if(String.isBlank(itemId)){
                    OrderItem orderItem = new OrderItem();
                    
                    orderItem.unitPrice =Decimal.valueOf(string.valueOf(item.get('UnitPrice')));
                    //product2id:product2id,
                    orderitem.orderid = (string)item.get('OrderId');
                   
                    orderitem.quantity = (Integer)item.get('qty');
                    orderItem.pricebookEntryId = (string)item.get('PricebookEntryId');
                    orderItem.Type__c = (string)item.get('type');
                    orderItem.category__c = (string)item.get('category');
                    orderItem.Description = (string)item.get('Description');
                    orderItemList.add(orderItem);
                }else{
                    OrderItem orderItem = new OrderItem();
                    orderItem.Id = itemId;
                    orderItem.unitPrice =Decimal.valueOf(string.valueOf(item.get('UnitPrice')));
                    orderItem.Description = (string)item.get('Description');
                    orderItemList.add(orderItem);
                }
            }
            system.debug(orderItemList);
            if(!orderItemList.isEmpty())
                upsert orderItemList;
            
            return [SELECT Id,Description,OrderId,unitPrice,product2Id,PricebookEntryId,Product2.Type__c,Product2.family,Product2.Name,Product2.Tool_Note__c FROM OrderItem WHERE OrderId=:orderid AND Product2.Type__c ='Additional Charges'];
        //} catch (Exception e) {
          //  throw new AuraHandledException(e.getMessage());
        //}

    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(string orderid){

        return [SELECT Id,OrderId,Total_Handling_Fee__c, Tool_Handling_Fee_Per_Item__c,UnitPrice,Requested_Borrowing_Period__c,Product2.Name,Schedule_Return_Date__c,Status__c,Quantity,Reserved_Quantity__c FROM OrderItem WHERE OrderId =: orderid AND Product2.Type__c ='Tool'];
    }


    @AuraEnabled
    public static List<OrderItem> deleteItems(String orderItems){
        system.debug(orderItems);
        list<OrderItem> orderItemList = new List<orderItem>();
        List<Object> ordItemList = (List<Object>) json.deserializeUntyped(orderItems);
        String orderid;
        for(Object obj: ordItemList){
            Map<String, object> item = (Map<String, object>)obj;
            String itemId = (string)item.get('Id');
            if(orderid == Null)
                orderid = (string)item.get('OrderId');
            
            system.debug(item.get('OrderId'));
            if(!String.isBlank(itemId)){
                OrderItem orderItem = new OrderItem();
                orderItem.Id = itemId;
                orderItemList.add(orderItem);
            }
        }

        if(!orderItemList.isEmpty())
            delete orderItemList;

    
        return [SELECT Id,OrderId,Description,unitPrice,product2Id,PricebookEntryId,Product2.Type__c,Product2.family,Product2.Name,Product2.Tool_Note__c FROM OrderItem WHERE OrderId=:orderid AND Product2.Type__c ='Additional Charges'];

    }
}