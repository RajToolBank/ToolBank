public class RK_UpdateOrderItemTask {
    public static void updateTask(List<OrderItem> orderItemList, Map<Id, OrderItem> itemOldMap) {
       /* set<Id> orderIds = new Set<Id>();
        Map<String,OrderItem> mapOrderIdToItemReturnDate = new Map<String,OrderItem>();
        Map<String,Task> mapOrderIdToTaskReturnDate = new Map<String,Task>();
        for(OrderItem ordItem :orderItemList) {
            if(itemOldMap.get(ordItem.Id).Schedule_Return_Date__c != ordItem.Schedule_Return_Date__c) {
                orderIds.add(ordItem.OrderId);
            }
        }
        List<Task> createTaskList = new List<Task>();
        //List<Task> updateTaskList = new List<Task>();
        List<Task> deleteTaskList = new List<Task>();
        for(Task tas :[Select id, type, whatId, ActivityDate, OwnerId, Subject, Status from Task where whatid in :orderIds AND type = 'Return']) {
            String uniKey = tas.WhatId+' - '+tas.ActivityDate.format();
            mapOrderIdToTaskReturnDate.put(uniKey, tas);
        }
        for(OrderItem ordItem :[Select id, OrderId, Order.OrderNumber, Order.OwnerId, Schedule_Return_Date__c from OrderItem where OrderId In :orderIds AND Schedule_Return_Date__c != NULL]) {
            String uniKey = ordItem.OrderId+' - '+ordItem.Schedule_Return_Date__c.format();
            mapOrderIdToItemReturnDate.put(uniKey, ordItem);
        }
        for(String str :mapOrderIdToItemReturnDate.keySet()) {
            if(!mapOrderIdToTaskReturnDate.containsKey(str)) {
                Task returnTask = new Task();
                returnTask.Subject = mapOrderIdToItemReturnDate.get(str).Order.OrderNumber+' - Return Task';
                //returnTask.OwnerId = mapOrderIdToItemReturnDate.get(str).Order.OwnerId;
                returnTask.ActivityDate = mapOrderIdToItemReturnDate.get(str).Schedule_Return_Date__c;
                returnTask.Type = 'Return';
                returnTask.whatId = mapOrderIdToItemReturnDate.get(str).OrderId;
                createTaskList.add(returnTask);
            }
        }
        for(String str :mapOrderIdToTaskReturnDate.keySet()) {
            if(!mapOrderIdToItemReturnDate.containsKey(str)) {
                Task returnTask = mapOrderIdToTaskReturnDate.get(str);
                deleteTaskList.add(returnTask);
            }
        }
        if(!createTaskList.isEmpty()) {
            insert createTaskList;
        }
        if(!deleteTaskList.isEmpty()) {
            delete deleteTaskList;
        }*/
    }
}