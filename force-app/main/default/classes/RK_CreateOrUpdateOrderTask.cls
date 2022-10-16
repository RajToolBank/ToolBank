public class RK_CreateOrUpdateOrderTask {
    public static void createUpdateTask(List<Order> ordList) {
        
        Map<Id,List<Task>> mapOrderIdToTaskList = new Map<Id,List<Task>>();
        Map<Id,Task> mapOrderIdToPickUpTask = new Map<Id,Task>();
        Set<Id> orderIds = new Set<Id>();
        Map<String,Date> mapOrderIdToItemReturnDate = new Map<String,Date>();
        Map<String,Date> mapOrderIdToTaskReturnDate = new Map<String,Date>();
        for(Order ord :ordList) {
            if(ord.status == 'Confirmed' || ord.status == 'Fulfilled' || ord.status == 'Returned') {
                orderIds.add(ord.Id);
            }
        }
        for(OrderItem ordItem :[Select id, OrderId, Schedule_Return_Date__c from OrderItem where OrderId In :orderIds AND Schedule_Return_Date__c != NULL]) {
            String uniKey = ordItem.OrderId+' - '+ordItem.Schedule_Return_Date__c.format();
            mapOrderIdToItemReturnDate.put(uniKey, ordItem.Schedule_Return_Date__c);
        }
        for(Task tas :[Select id, type, whatId, ActivityDate, OwnerId, Subject, Status from Task where whatid in :orderIds AND (type = 'Return' OR type = 'Pick-Up')]) {
            if(mapOrderIdToTaskList.containsKey(tas.whatId)) {
                List<Task> tempList = mapOrderIdToTaskList.get(tas.whatId);
                tempList.add(tas);
                mapOrderIdToTaskList.put(tas.whatId, tempList);
            } else {
                mapOrderIdToTaskList.put(tas.whatId, new List<Task>{tas});
            }
            if(tas.Type == 'Return') {
                String uniKey = tas.WhatId+' - '+tas.ActivityDate.format();
                mapOrderIdToTaskReturnDate.put(uniKey, tas.ActivityDate);
            } else if(tas.Type == 'Pick-Up') {
                mapOrderIdToPickUpTask.put(tas.whatId, tas);
            }
        }
        system.debug('pickUptask-->'+mapOrderIdToPickUpTask);
        List<Task> createTaskList = new List<Task>();
        List<Task> updateTaskList = new List<Task>();
        for(Order ord :ordList) {
            if(ord.Status == 'Confirmed') {
                if(mapOrderIdToPickUpTask.containsKey(ord.Id)) {
                    Task tas = mapOrderIdToPickUpTask.get(ord.Id);
                    tas.Subject = ord.OrderNumber+' - Pick-Up Task';
                    //tas.OwnerId = ord.OwnerId;
                    tas.ActivityDate = ord.EffectiveDate;
                    updateTaskList.add(tas);
                } else {
                    Task pickUpTask = new Task();
                    pickUpTask.Subject = ord.OrderNumber+' - Pick-Up Task';
                    //pickUpTask.OwnerId = ord.OwnerId;
                    pickUpTask.ActivityDate = ord.EffectiveDate;
                    pickUpTask.Type = 'Pick-Up';
                    pickUpTask.whatId = ord.id;
                    createTaskList.add(pickUpTask);
                }
                if(!mapOrderIdToItemReturnDate.values().IsEmpty()) {
                    for(String str :mapOrderIdToItemReturnDate.keySet()) {
                        if(!mapOrderIdToTaskReturnDate.containsKey(str)) {
                            Task returnTask = new Task();
                            returnTask.Subject = ord.OrderNumber+' - Return Task';
                           // returnTask.OwnerId = ord.OwnerId;
                            returnTask.ActivityDate = mapOrderIdToItemReturnDate.get(str);
                            returnTask.Type = 'Return';
                            returnTask.whatId = ord.Id;
                            createTaskList.add(returnTask);
                        }
                    } 
                }
            } else if(ord.Status == 'Fulfilled' && mapOrderIdToPickUpTask.containsKey(ord.Id)) {
                Task temptask = mapOrderIdToPickUpTask.get(ord.id);
                temptask.status = 'Completed';
                updateTaskList.add(temptask);
            } else if(ord.Status == 'Returned' && !mapOrderIdToTaskReturnDate.values().IsEmpty()) {
                for(Task tas :mapOrderIdToTaskList.get(ord.Id)) {
                    if(tas.Type == 'Return') {
                        tas.status = 'Completed';
                        updateTaskList.add(tas);
                    }
                }
            }
        }
        if(!createTaskList.isEmpty()) {
            insert createTaskList;
        }
        if(!updateTaskList.isEmpty()) {
            update updateTaskList;
        }
    }
}