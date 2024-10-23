trigger OrderTrigger on Order (before update, after update) {


    if(trigger.isBefore && trigger.isUpdate){
        OrderTriggerHelper.updateStatusValidation(trigger.new, trigger.oldMap);
    }
    else if(trigger.isAfter && trigger.isUpdate){
        //OrderCancelOrItemDeleteController.orderCancelled(trigger.new);
        RK_CreateOrUpdateOrderTask.createUpdateTask(trigger.new);
    }

}