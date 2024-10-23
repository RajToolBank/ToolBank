public class OrderCancelOrItemDeleteController {
    
    public static String userId = UserInfo.getUserId();
    public static String className = 'OrderCancelOrItemDeleteController';
    public static String methodName;
    public static String logLineNumber;
    public static String debugLog;
    public static String recordId;
    public static Boolean orderRecursion = false;

    public static void orderCancelled(List<Order> triggerNew){
        methodName = 'orderCancelled';
        orderRecursion = true;
        List<Order> cancelledOrderList = new List<Order>();
        set<Id> AffiliateIdSet = new set<Id>();
        for(Order order: triggerNew){
            if(order.status.equalsIgnoreCase('Cancelled')){
                cancelledOrderList.add(order);
                AffiliateIdSet.add(order.Affiliate__c);
            }
        }
        if(!cancelledOrderList.isEmpty()){
            List<OrderItem> cancelledOrderItemList = [SELECT Id,LastModifiedDate,Reserved_Quantity__c,Product2Id,Order.Affiliate__c,Schedule_Pick_Date__c,Schedule_Return_Date__c FROM OrderItem WHERE OrderId IN: cancelledOrderList];
            system.debug('cancelledOrderItemList :: '+ cancelledOrderItemList);
            Set<Id> productIdSet = new set<Id>();
            List<Date> dateList = new List<Date>();
            List<Date> lastModifieddateList = new List<Date>();
            for(OrderItem item: cancelledOrderItemList){
                productIdSet.add(item.product2Id);
                    
                dateList.add(item.Schedule_Pick_Date__c);
                dateList.add(item.Schedule_Return_Date__c);
                lastModifieddateList.add(Date.valueOf(item.LastModifiedDate.addDays(1)));
            }

            dateList.sort();
            lastModifieddateList.sort();
            Date minPickDate = dateList[0];
            Date maxReturnDate = dateList[dateList.size()-1];
            system.debug('lastModifieddateList :: '+ lastModifieddateList);
            List<OrderItem> otherItemList =   [SELECT Id,product2Id,
                                            PriceBookEntryId,
                                            Order.Affiliate__c,
                                            Inventory_Tool__c,
                                            Affiliate_Handling_Fee__c,
                                            LastModifiedDate,Quantity,
                                            Lowest_Available_Quantity_For_this_Item__c,
                                            Reserved_Quantity__c,
                                            Schedule_Pick_Date__c,
                                            Schedule_Return_Date__c 
                                            FROM OrderItem 
                                            WHERE product2Id IN: productIdSet 
                                            AND Id NOT IN: cancelledOrderItemList
                                            AND Order.Affiliate__c IN: AffiliateIdSet
                                            AND (Status__c = 'Unconfirmed' OR Status__c = 'Confirmed')
                                            AND LastModifiedDate <: lastModifieddateList[lastModifieddateList.size()-1]
                                            AND Product2.Type__c = 'Tool'
                                            ORDER BY LastModifiedDate ASC];
            system.debug('otherItemList :: '+ otherItemList);
            Map<Id,Map<id, List<OrderItem>>> affiliateToproductIdToItemListMap = new Map<Id,Map<Id, List<OrderItem>>>();

            for(OrderItem item: otherItemList){

                if(!affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c))
                    affiliateToproductIdToItemListMap.put(item.Order.Affiliate__c, new Map<id, List<OrderItem>>());

                Map<id, List<OrderItem>> productIdToItemListMap = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c);
                
                if(!productIdToItemListMap.containsKey(item.product2Id))
                    productIdToItemListMap.put(item.product2Id, new List<OrderItem>());

                productIdToItemListMap.get(item.product2Id).add(item);
            }
            List<OrderItem> ListToUpdate = new List<OrderItem>();
            for(OrderItem item: cancelledOrderItemList){
                system.debug(item);
                if(affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c)){
                    system.debug(affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id));
                    List<OrderItem> itemList = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id);
                    if(item.Reserved_Quantity__c >0)
                        lowestQuantityItemDate(item,itemList);

                    if(itemList != null && !itemList.isEmpty())
                        ListToUpdate.addAll(itemList);
                }
                item.status__c = 'Cancelled';
                item.Reserved_Quantity__c = 0;
                ListToUpdate.add(item);
            
            }
            DebugLogUtil debugLogger = new DebugLogUtil();
            logLineNumber = '91';
            debugLog = JSON.serialize(ListToUpdate);
            recordId = JSON.serialize(cancelledOrderList);
            debugLogger.publishDebugLog(debugLog, className, methodName, logLineNumber, recordId, userId);
            if(!ListToUpdate.isEmpty())
                Update ListToUpdate;
        }
    }


    public static void lowestQuantityItemDate(orderItem orderItem, List<orderItem> existingOrderItems){
        methodName = 'lowestQuantityItemDate';
        Decimal reservedQuantity = orderItem.Reserved_Quantity__c;
        if(existingOrderItems != Null){
            for(OrderItem item: existingOrderItems){
                item.Reserved_Quantity__c = (item.Reserved_Quantity__c!= null?item.Reserved_Quantity__c:0);
                if(reservedQuantity >0 && item.LastModifiedDate <= OrderItem.LastModifiedDate && 
                    orderItem.Schedule_Pick_Date__c <= item.Schedule_Return_Date__c && 
                    orderItem.Schedule_Return_Date__c >= item.Schedule_Pick_Date__c && 
                    item.quantity > item.Reserved_Quantity__c) {
                        Decimal pending = item.quantity - item.Reserved_Quantity__c;
                        Decimal adjusted = reservedQuantity >= pending?pending:reservedQuantity;
                        item.Reserved_Quantity__c = (item.Reserved_Quantity__c!= null?item.Reserved_Quantity__c:0)+adjusted;

                        reservedQuantity = reservedQuantity - adjusted;
                }
            }
            DebugLogUtil debugLogger = new DebugLogUtil();
            logLineNumber = '114';
            debugLog = JSON.serialize(existingOrderItems);
            recordId = orderItem.OrderId;
            debugLogger.publishDebugLog(debugLog, className, methodName, logLineNumber, recordId, userId);
            if(!System.trigger.isExecuting || !System.trigger.isDelete)
                orderItem.Reserved_Quantity__c =0;
        }

       

    }

    public static void orderItemDelete(List<OrderItem> triggerOld){
        methodName = 'lowestQuantityItemDate';
        Set<Id> productIdSet = new set<Id>();
        List<Date> dateList = new List<Date>();
        List<Date> lastModifieddateList = new List<Date>();
        Map<Id,Id> AffiliateIdSet = new Map<Id,Id>();
        set<Id> orderIdSet = new set<Id>();
        for(OrderItem item: triggerOld){
            productIdSet.add(item.product2Id);
            orderIdSet.add(item.orderId);
            dateList.add(item.Schedule_Pick_Date__c);
            dateList.add(item.Schedule_Return_Date__c);
            lastModifieddateList.add(Date.valueOf(item.LastModifiedDate.addDays(1)));
        }

        dateList.sort();
        lastModifieddateList.sort();
        Date minPickDate = dateList.size()>0?dateList[0]:Null;
        Date maxReturnDate = dateList.size()>0?dateList[dateList.size()-1]:Null;
        system.debug('dateList :: '+ dateList);

        for(Order order:[SELECT Id, Affiliate__c FROM Order WHERE Id IN:orderIdSet]){
            AffiliateIdSet.put(order.Id,order.Affiliate__c);
        }
        List<OrderItem> otherItemList =   [SELECT Id,product2Id,
                                        PriceBookEntryId,
                                        Order.Affiliate__c,
                                        Inventory_Tool__c,
                                        Affiliate_Handling_Fee__c,
                                        LastModifiedDate,Quantity,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Reserved_Quantity__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE product2Id IN: productIdSet 
                                        AND Id NOT IN: triggerOld
                                        AND Order.Affiliate__c IN: AffiliateIdSet.values()
                                        AND Status__c = 'Unconfirmed'
                                        //AND Schedule_Pick_Date__c <=: maxReturnDate
                                        //AND Schedule_Return_Date__c >=: minPickDate
                                        //AND LastModifiedDate <: lastModifieddateList[lastModifieddateList.size()-1]
                                        AND Product2.Type__c = 'Tool'
                                        ORDER BY LastModifiedDate ASC];
        
        Map<Id,Map<id, List<OrderItem>>> affiliateToproductIdToItemListMap = new Map<Id,Map<Id, List<OrderItem>>>();

        for(OrderItem item: otherItemList){

            if(!affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c))
                affiliateToproductIdToItemListMap.put(item.Order.Affiliate__c, new Map<id, List<OrderItem>>());

            Map<id, List<OrderItem>> productIdToItemListMap = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c);
            
            if(!productIdToItemListMap.containsKey(item.product2Id))
                productIdToItemListMap.put(item.product2Id, new List<OrderItem>());


                    productIdToItemListMap.get(item.product2Id).add(item);
        }
        List<OrderItem> ListToUpdate = new List<OrderItem>();
        set<Id> productIds = new Set<Id>();
        for(OrderItem item: triggerOld){
            system.debug(item);
            
            if(AffiliateIdSet.containsKey(item.OrderId) && affiliateToproductIdToItemListMap.containsKey(AffiliateIdSet.get(item.OrderId))){
                system.debug(affiliateToproductIdToItemListMap.get(AffiliateIdSet.get(item.OrderId)).get(item.product2Id));
                List<OrderItem> itemList = affiliateToproductIdToItemListMap.get(AffiliateIdSet.get(item.OrderId)).get(item.product2Id);
                if(item.Reserved_Quantity__c >0)
                    lowestQuantityItemDate(item,itemList);

                if(!productIds.contains(item.product2Id) && itemList!= null && !itemList.isEmpty()){
                    ListToUpdate.addAll(itemList);
                    productIds.add(item.product2Id);
                }
            }
        }
        DebugLogUtil debugLogger = new DebugLogUtil();
        logLineNumber = '199';
        debugLog = JSON.serialize(ListToUpdate);
        recordId = JSON.serialize(orderIdSet);
        debugLogger.publishDebugLog(debugLog, className, methodName, logLineNumber, recordId, userId);
        if(!ListToUpdate.isEmpty())
            Update ListToUpdate;
    }
}