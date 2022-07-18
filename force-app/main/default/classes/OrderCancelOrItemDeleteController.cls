public with sharing class OrderCancelOrItemDeleteController {
    

    public static void orderCancelled(List<Order> triggerNew){
        List<Order> cancelledOrderList = new List<Order>();
        set<Id> AffiliateIdSet = new set<Id>();
        for(Order order: triggerNew){
            if(order.status.equalsIgnoreCase('Cancelled')){
                cancelledOrderList.add(order);
                AffiliateIdSet.add(order.Affiliate__c);
            }
        }
if(!cancelledOrderList.isEmpty()){
        List<OrderItem> cancelledOrderItemList = [SELECT Id,Order.Affiliate__c,Schedule_Pick_Date__c,Schedule_Return_Date__c FROM OrderItem WHERE OrderId IN: cancelledOrderList];
        
        Set<Id> productIdSet = new set<Id>();
        List<Date> dateList = new List<Date>();

        for(OrderItem item: cancelledOrderItemList){
            productIdSet.add(item.product2Id);
                
            dateList.add(item.Schedule_Pick_Date__c);
            dateList.add(item.Schedule_Return_Date__c);
        }

        dateList.sort();
        Date minPickDate = dateList[0];
        Date maxReturnDate = dateList[dateList.size()-1];
        system.debug('dateList :: '+ dateList);
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
                                        AND Schedule_Pick_Date__c <=: maxReturnDate
                                        AND Schedule_Return_Date__c >=: minPickDate
                                        AND Product2.Type__c = 'Tool'
                                        ORDER BY LastModifiedDate ASC];
        
        Map<Id,Map<id, List<OrderItem>>> affiliateToproductIdToItemListMap = new Map<Id,Map<Id, List<OrderItem>>>();

        for(OrderItem item: otherItemList){

            if(!affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c))
                affiliateToproductIdToItemListMap.put(item.product2Id, new Map<id, List<OrderItem>>());

            Map<id, List<OrderItem>> productIdToItemListMap = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c);
            
            if(!productIdToItemListMap.containsKey(item.product2Id))
                productIdToItemListMap.put(item.product2Id, new List<OrderItem>());

            productIdToItemListMap.get(item.product2Id).add(item);
        }
        List<OrderItem> ListToUpdate = new List<OrderItem>();
        for(OrderItem item: cancelledOrderItemList){
            system.debug(item);
            system.debug(affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id));
            List<OrderItem> itemList = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id);
            if(item.Reserved_Quantity__c >0)
                lowestQuantityItemDate(item,itemList);

            item.status__c = 'Cancelled';

            ListToUpdate.add(item);
            if(!itemList.isEmpty())
                ListToUpdate.addAll(itemList);
           
        }
        if(!ListToUpdate.isEmpty())
            Update ListToUpdate;
        }
    }


    public static void lowestQuantityItemDate(orderItem orderItem, List<orderItem> existingOrderItems){

        Decimal reservedQuantity = orderItem.Reserved_Quantity__c;
        if(existingOrderItems != Null){
            for(OrderItem item: existingOrderItems){
                item.Reserved_Quantity__c = (item.Reserved_Quantity__c!= null?item.Reserved_Quantity__c:0);
                if(reservedQuantity >0 && item.LastModifiedDate <= OrderItem.LastModifiedDate && 
                    orderItem.Schedule_Pick_Date__c <= item.Schedule_Return_Date__c && 
                    orderItem.Schedule_Return_Date__c >= item.Schedule_Pick_Date__c && item.quantity > item.Reserved_Quantity__c) {
                        Decimal pending = item.quantity - item.Reserved_Quantity__c;
                        Decimal adjusted = reservedQuantity >= pending?pending:reservedQuantity;
                        item.Reserved_Quantity__c = (item.Reserved_Quantity__c!= null?item.Reserved_Quantity__c:0)+adjusted;

                        reservedQuantity = reservedQuantity - adjusted;
                }
            }
            orderItem.Reserved_Quantity__c =0;
        }

       

    }

    public static void orderItemDelete(List<OrderItem> triggerOld){
        Set<Id> productIdSet = new set<Id>();
        List<Date> dateList = new List<Date>();
        set<Id> AffiliateIdSet = new set<Id>();
        set<Id> orderIdSet = new set<Id>();
        for(OrderItem item: triggerOld){
            productIdSet.add(item.product2Id);
            orderIdSet.add(item.orderId);
            dateList.add(item.Schedule_Pick_Date__c);
            dateList.add(item.Schedule_Return_Date__c);
        }

        dateList.sort();
        Date minPickDate = dateList[0];
        Date maxReturnDate = dateList[dateList.size()-1];
        system.debug('dateList :: '+ dateList);

        for(Order order:[SELECT Id, Affiliate__c FROM Order WHERE Id IN:orderIdSet]){
            AffiliateIdSet.add(order.Affiliate__c);
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
                                        AND Order.Affiliate__c IN: AffiliateIdSet
                                        AND Schedule_Pick_Date__c <=: maxReturnDate
                                        AND Schedule_Return_Date__c >=: minPickDate
                                        AND Product2.Type__c = 'Tool'
                                        ORDER BY LastModifiedDate ASC];
        
        Map<Id,Map<id, List<OrderItem>>> affiliateToproductIdToItemListMap = new Map<Id,Map<Id, List<OrderItem>>>();

        for(OrderItem item: otherItemList){

            if(!affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c))
                affiliateToproductIdToItemListMap.put(item.product2Id, new Map<id, List<OrderItem>>());

            Map<id, List<OrderItem>> productIdToItemListMap = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c);
            
            if(!productIdToItemListMap.containsKey(item.product2Id))
                productIdToItemListMap.put(item.product2Id, new List<OrderItem>());

            productIdToItemListMap.get(item.product2Id).add(item);
        }
        List<OrderItem> ListToUpdate = new List<OrderItem>();
        for(OrderItem item: triggerOld){
            system.debug(item);
            system.debug(affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id));
            List<OrderItem> itemList = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id);
            if(item.Reserved_Quantity__c >0)
                lowestQuantityItemDate(item,itemList);

            if(!itemList.isEmpty())
                ListToUpdate.addAll(itemList);
           
        }
        if(!ListToUpdate.isEmpty())
            Update ListToUpdate;
    }
}
