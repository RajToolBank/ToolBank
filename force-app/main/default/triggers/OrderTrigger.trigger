trigger OrderTrigger on Order (after update) {
    OrderCancelOrItemDeleteController.orderCancelled(trigger.new);
}