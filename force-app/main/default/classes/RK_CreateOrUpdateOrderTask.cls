public class RK_CreateOrUpdateOrderTask {
    public static void createUpdateTask(List<Order> ordList) {
       
        Map<Id,List<Task>> mapOrderIdToTaskList = new Map<Id,List<Task>>();
        Map<Id,Task> mapOrderIdToPickUpTask = new Map<Id,Task>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Map<String,Date> mapOrderIdToItemReturnDate = new Map<String,Date>();
        Map<String,Date> mapOrderIdToTaskReturnDate = new Map<String,Date>();
        for(Order ord :ordList) {
            if(ord.status == 'Confirmed' || ord.status == 'Fulfilled'){// || ord.status == 'Returned') {
                orderIds.add(ord.Id);
                accIds.add(ord.accountId);
            }
        }
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id,Name,parent.Name FROM Account WHERE Id IN:accIds]);
        Set<String> accNameSet = new Set<String>();
        for(Account acc: accMap.values()){
            accNameSet.add(acc.parent.Name);
        }
        Map<String,Toolbank_Help_Page__mdt> accNameToMetaMap = new Map<String,Toolbank_Help_Page__mdt>();
        for(Toolbank_Help_Page__mdt meta: [SELECT Id,MasterLabel,Affiliate_Queue_Id__c,Affiliate_Account_Id__c FROM Toolbank_Help_Page__mdt WHERE MasterLabel IN: accNameSet]){
            accNameToMetaMap.put(meta.Affiliate_Account_Id__c, meta);   
        }

       /* for(OrderItem ordItem :[Select id, OrderId, Schedule_Return_Date__c from OrderItem where OrderId In :orderIds AND Schedule_Return_Date__c != NULL]) {
            String uniKey = ordItem.OrderId+' - '+ordItem.Schedule_Return_Date__c.format();
            mapOrderIdToItemReturnDate.put(uniKey, ordItem.Schedule_Return_Date__c);
        }*/
        for(Task tas :[Select id, type, whatId, ActivityDate, 
                      OwnerId, Subject, Status 
                      from Task 
                      where whatid in :orderIds 
                      AND (type = 'Pick-Up' 
                      /*OR type = 'Return'*/)]) {
            /*if(mapOrderIdToTaskList.containsKey(tas.whatId)) {
                List<Task> tempList = mapOrderIdToTaskList.get(tas.whatId);
                tempList.add(tas);
                mapOrderIdToTaskList.put(tas.whatId, tempList);
            } else {
                mapOrderIdToTaskList.put(tas.whatId, new List<Task>{tas});
            }
            if(tas.Type == 'Return') {
                String uniKey = tas.WhatId+' - '+tas.ActivityDate.format();
                mapOrderIdToTaskReturnDate.put(uniKey, tas.ActivityDate);
            } else*/ if(tas.Type == 'Pick-Up') {
                mapOrderIdToPickUpTask.put(tas.whatId, tas);
            }
        }
        system.debug('pickUptask-->'+mapOrderIdToPickUpTask);
        List<Task> createTaskList = new List<Task>();
        List<Task> updateTaskList = new List<Task>();
        for(Order ord :ordList) {
            if(ord.Status == 'Confirmed') {
                String accountName = accMap.get(ord.accountId).Name;
                String ownerId = accNameToMetaMap.containsKey(ord.Affiliate__c)?accNameToMetaMap.get(ord.Affiliate__c).Affiliate_Queue_Id__c:userInfo.getUserId();
                if(mapOrderIdToPickUpTask.containsKey(ord.Id)) {
                    Task tas = mapOrderIdToPickUpTask.get(ord.Id);
                    
                    tas.Subject = 'Pickup '+accountName;
                    tas.status = 'Schedule';
                    tas.OwnerId = ownerId != Null?ownerId:userInfo.getUserId();
                    tas.ActivityDate = ord.EffectiveDate;
                    tas.Due_Date_Time__c = DateTime.newInstance(ord.EffectiveDate!=null?ord.EffectiveDate:system.today(),ord.Scheduled_Pickup_Time__c!= null?ord.Scheduled_Pickup_Time__c:system.now().time());
                    updateTaskList.add(tas);
                } else {
                    Task pickUpTask = new Task();
                    pickUpTask.Subject = 'Pickup '+accountName;
                    pickUpTask.status = 'Schedule';
                    pickUpTask.OwnerId = ownerId != Null?ownerId:userInfo.getUserId();
                    pickUpTask.ActivityDate = ord.EffectiveDate;
                    pickUpTask.Due_Date_Time__c = DateTime.newInstance(ord.EffectiveDate!=null?ord.EffectiveDate:system.today(),ord.Scheduled_Pickup_Time__c!= null?ord.Scheduled_Pickup_Time__c:system.now().time());
                    pickUpTask.Type = 'Pick-Up';
                    pickUpTask.whatId = ord.id;
                    createTaskList.add(pickUpTask);
                }
                /*if(!mapOrderIdToItemReturnDate.values().IsEmpty()) {
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
                }*/
            } else if(ord.Status == 'Fulfilled' && mapOrderIdToPickUpTask.containsKey(ord.Id)) {
                Task temptask = mapOrderIdToPickUpTask.get(ord.id);
                temptask.status = 'Completed';
                updateTaskList.add(temptask);
            } /*else if(ord.Status == 'Returned' && !mapOrderIdToTaskReturnDate.values().IsEmpty()) {
                for(Task tas :mapOrderIdToTaskList.get(ord.Id)) {
                    if(tas.Type == 'Return') {
                        tas.status = 'Completed';
                        updateTaskList.add(tas);
                    }
                }
            }*/
        }
        if(!createTaskList.isEmpty()) {
            insert createTaskList;
        }
        if(!updateTaskList.isEmpty()) {
            update updateTaskList;
        }
    }
}