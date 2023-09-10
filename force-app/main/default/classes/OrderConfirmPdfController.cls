public without sharing class OrderConfirmPdfController {
    
    public List<OrderItem> orderItemList{get;set;}

    public OrderConfirmPdfController(ApexPages.StandardController SC){
        String orderId = sc.getId();

        orderItemList = [SELECT Id,product2.Type__c,status__c,product2.name,Quantity,Reserved_Quantity__c FROM OrderItem WHERE OrderId =: orderId ORDER BY product2.name ASC];
    }
}