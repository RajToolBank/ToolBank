public without Sharing class OrderCancelledCmpController {
    
    @AuraEnabled
    public static string cancelOrder(String recordId){
        try {
            User user = [SELECT Id, Profile.Name FROM User WHERE Id =: userinfo.getUserId()];
            if(!user.profile.Name.containsIgnoreCase('TB Member Plus') && !user.profile.Name.containsIgnoreCase('TB Member')){

                Order order = [SELECT Id,Status FROM Order WHERE Id=:recordId];
                Boolean  confirmed = 'Confirmed'.equalsIgnoreCase(Order.status);
                Boolean unconfirmed = 'Unconfirmed'.equalsIgnoreCase(Order.status);
                Boolean partialConfirmed = 'Partially Confirmed'.equalsIgnoreCase(Order.status);
                if( confirmed || unconfirmed || partialConfirmed){
                    order.status = 'Cancelled';
                    ByPassValidations.ordStatusValidation=true;
                    update order;
                    return 'Order cancelled successfully.';
                }else {
                    return 'Only confirmed or unconfirmed orders are allowed to cancel.';
                }
            }else{
                return 'You do not have permission to cancel the order.';
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string deleteOrder(String recordId){
       // try {
            User user = [SELECT Id, Profile.Name FROM User WHERE Id =: userinfo.getUserId()];
            if(!user.profile.Name.equalsIgnoreCase('TB Member Plus') && !user.profile.Name.equalsIgnoreCase('TB Member')){

                Order order = [SELECT Id,Status FROM Order WHERE Id=:recordId];
                Boolean  confirmed = 'Confirmed'.equalsIgnoreCase(Order.status);
                Boolean unconfirmed = 'Unconfirmed'.equalsIgnoreCase(Order.status);
                Boolean partialConfirmed = 'Partially Confirmed'.equalsIgnoreCase(Order.status);
                if( confirmed || unconfirmed || partialConfirmed){
                    List<OrderItem> itemsToDelete = [SELECT Id,product2Id,quantity,Reserved_Quantity__c,orderId,Schedule_Pick_Date__c,Schedule_Return_Date__c,LastModifiedDate FROM OrderItem WHERE OrderId =: recordId];
                    ByPassValidations.ordStatusValidation=true;
                    OrderCancelOrItemDeleteController.orderItemDelete(itemsToDelete);
                    delete order;
                    return 'Order deleted successfully.';
                }else {
                    return 'Only confirmed or unconfirmed orders are allowed to delete.';
                }
            }else{
                return 'You do not have permission to delete the order.';
            }
            
        //} catch (Exception e) {
          //  throw new AuraHandledException(e.getMessage());
        //}
        
    }
}