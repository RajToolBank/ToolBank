trigger orderItemTrigger on OrderItem (before update, after insert, after update, after delete) {

    if(trigger.isBefore && trigger.isUpdate)
        OrderItemHelperClass.quantityAndPriceValidation(trigger.new, trigger.oldMap);

    if(trigger.isAfter && trigger.isInsert){
        OrderItemHelperClass.createTransactionOnInsert(trigger.new);
    }
    
    if(trigger.isAfter && trigger.isUpdate) {
        OrderItemHelperClass.createTransaction(trigger.new, trigger.oldMap);
    }
    if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert) && (!OrderItemHelperClass.recursion))// || !OrderItemHelperClass.recursionUpdate))
        OrderItemHelperClass.handleStatus(trigger.new,trigger.oldMap);

    
    if(trigger.isAfter && (trigger.isDelete)){
        //OrderCancelOrItemDeleteController.orderItemDelete(trigger.old);
        If(!OrderItemHelperClass.recursion)
            OrderItemHelperClass.handleStatus(trigger.old,trigger.oldMap);
    }
}