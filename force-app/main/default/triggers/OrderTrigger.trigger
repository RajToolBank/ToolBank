trigger OrderTrigger on Order (after update) {
    OrderCancelOrItemDeleteController.orderCancelled(trigger.new);
    RK_CreateOrUpdateOrderTask.createUpdateTask(trigger.new);
}