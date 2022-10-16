trigger orderItemTrigger on OrderItem (after insert, after update,after delete) {
    
    if(trigger.isAfter && trigger.isUpdate) {
        OrderItemHelperClass.createTransaction(trigger.new, trigger.oldMap);
        RK_UpdateOrderItemTask.updateTask(trigger.new, trigger.oldMap);
    }
    if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert) && !OrderItemHelperClass.recursion)
        OrderItemHelperClass.handleStatus(trigger.new);
    
    if(trigger.isAfter && (trigger.isDelete))
        OrderCancelOrItemDeleteController.orderItemDelete(trigger.old);
}