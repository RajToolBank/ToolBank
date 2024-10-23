public class LowestQuantityCalculateClasss {

public static void lowestQuantityOrder2(List<Order> orderList){
    List<OrderItem> newOrderItemList = lowestQuantityOrder3( orderList);
    update newOrderItemList;


}
    
    public static  List<OrderItem> lowestQuantityOrder3(List<Order> orderList){
        List<Date> dateList = new List<Date>();
        Map<Id, Order> orderMap = new Map<Id, Order>(orderList);
        List<OrderItem> newOrderItemList = [SELECT product2.Name,
                                            Id,
                                            Quantity,
                                            Order.Affiliate__c,
                                            Reserved_Quantity__c,
                                            Affiliate_Handling_Fee__c,
                                            Inventory_Tool__r.Current_Inventory_F__c,
                                            Inventory_Tool__r.On_Shelf_Quantity_F__c,
                                            product2Id,
                                            PriceBookEntryId,
                                            Inventory_Tool__c,
                                            Product2.productCode,
                                            product2.Tool_Note__c,
                                            Requested_Borrowing_Period__c,
                                            Tool_Handling_Fee_Per_Item__c,
                                            Status__c,
                                            UnitPrice,
                                            Total_Handling_Fee__c,
                                            LastModifiedDate,
                                            Schedule_Pick_Date__c,
                                            Schedule_Return_Date__c 
                                            FROM OrderItem 
                                            WHERE OrderId IN:orderList
                                            AND Product2.type__c = 'Tool' 
                                            AND Status__c != 'Returned'
                                            ORDER BY product2.Name ASC];
        if(newOrderItemList != null && newOrderItemList.size()>0){
            Set<Id> productIdSet = new set<Id>();

            for(OrderItem item: newOrderItemList){
                productIdSet.add(item.product2Id);
            //  for(Date d=item.Schedule_Pick_Date__c; d<=item.Schedule_Return_Date__c;d.addDays(1)){
                    
                    dateList.add(item.Schedule_Pick_Date__c);
                    dateList.add(item.Schedule_Return_Date__c);
                //}
            }

            dateList.sort();
            Date minPickDate = dateList[0];
            Date maxReturnDate = dateList[dateList.size()-1];
            system.debug('dateList :: '+ dateList);
            List<OrderItem> oldItemList =   [SELECT Id,product2Id,
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
                                            WHERE Product2.Type__c = 'Tool'
                                            AND Status__c != 'Returned'
                                            AND Status__c != 'Cancelled'
                                            AND Order.Affiliate__c =: orderList[0].Affiliate__c
                                            AND product2Id IN: productIdSet 
                                            AND Id NOT IN: newOrderItemList
                                            AND Schedule_Pick_Date__c <=: maxReturnDate
                                            AND Schedule_Return_Date__c >=: minPickDate
                                            ORDER BY LastModifiedDate ASC];
            
            Map<Id,Map<id, List<OrderItem>>> affiliateToproductIdToItemListMap = new Map<Id,Map<Id, List<OrderItem>>>();

            for(OrderItem item: oldItemList){
                if(!affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c))
                    affiliateToproductIdToItemListMap.put(item.Order.Affiliate__c, new Map<id, List<OrderItem>>());

                Map<id, List<OrderItem>> productIdToItemListMap = affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c);

                if(!productIdToItemListMap.containsKey(item.product2Id))
                    productIdToItemListMap.put(item.product2Id, new List<OrderItem>());

                productIdToItemListMap.get(item.product2Id).add(item);
            }

            for(OrderItem item: newOrderItemList){
                system.debug(item);
                system.debug(item.Order.Affiliate__c);
                //system.debug(affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id));
                List<OrderItem> itemList = affiliateToproductIdToItemListMap.containsKey(item.Order.Affiliate__c)?affiliateToproductIdToItemListMap.get(item.Order.Affiliate__c).get(item.product2Id):null;
                Decimal lowest = lowestQuantityItemDate(item,itemList);
                item.Lowest_Available_Quantity_For_this_Item__c = lowest<0?0:lowest;
                lowest = lowest>item.quantity?item.quantity:lowest;
                if(item.Reserved_Quantity__c == Null)
                    item.Reserved_Quantity__c = lowest<0?0:lowest;
            }
                
            return newOrderItemList;
        } else return null;

    }

    @AuraEnabled
    public static Decimal singleItemLowestQuantity(String itemId, String product2Id, Date pickupDate, Date returnDate,String affilliateId){

        system.debug('itemId '+itemId +' product2Id '+product2Id+' pickupDate '+pickupDate+' returnDate '+returnDate);
        List<OrderItem> allItemList =   [SELECT Id,product2Id,
                                        LastModifiedDate,Quantity,
                                        PriceBookEntryId,
                                        Inventory_Tool__c,
                                        Affiliate_Handling_Fee__c,
                                        Inventory_Tool__r.Current_Inventory_F__c,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Reserved_Quantity__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE ((product2Id =: product2Id 
                                        AND Schedule_Pick_Date__c <=: returnDate
                                        AND Schedule_Return_Date__c >=: pickupDate)
                                        OR Id =: itemId)
                                        AND Product2.Type__c = 'Tool'
                                        AND Order.Affiliate__c =:affilliateId
                                        ORDER BY LastModifiedDate ASC];
        Map<Id, OrderItem> itemMap = new Map<Id, OrderItem>(allItemList);

        orderItem orderItem = itemMap.remove(itemId);orderItem.Schedule_Pick_Date__c = pickupDate;orderItem.Schedule_Return_Date__c = returnDate;

        return lowestQuantityItemDate(orderItem, DateTime.now(), itemMap.values());
    }
    
    
    
    public static Decimal lowestQuantityItemDate(orderItem orderItem, List<orderItem> existingOrderItems){

        
        List<Decimal> qtyList = new List<Decimal>();
        
            for(Date dt=orderItem.Schedule_Pick_Date__c;dt<=orderItem.Schedule_Return_Date__c;dt = dt.addDays(1)){
                Decimal reservedQuantity =0;
                Decimal currentInventory = orderItem.Inventory_Tool__r.Current_Inventory_F__c!= null?orderItem.Inventory_Tool__r.Current_Inventory_F__c:0;
                if(existingOrderItems != Null){
                    for(OrderItem item: existingOrderItems){

                        if(dt <= item.Schedule_Return_Date__c && dt >= item.Schedule_Pick_Date__c ) 
                        {
                                reservedQuantity += item.Reserved_Quantity__c!= Null?item.Reserved_Quantity__c:0;   
                                
                        }
                    }
            }

            currentInventory = currentInventory -reservedQuantity;
            qtyList.add(currentInventory);
            
        }

        qtyList.sort();

        Decimal lowestAvailableQuantity = (qtyList != Null && qtyList.size() >0)?qtyList[0]:0;

        return lowestAvailableQuantity;

    }

    public static Decimal lowestQuantityItemDate(orderItem orderItem, DateTime lastmodified, List<orderItem> existingOrderItems){

       
       
        Decimal lowestAvailableQuantity = lowestQuantityItemDate(orderItem,existingOrderItems);

        return lowestAvailableQuantity <0 ?0:lowestAvailableQuantity;

    }
    public Decimal lowestQuantityItem(orderItem orderItem, List<orderItem> existingOrderItems){

        Decimal reservedQuantity = 0;
        for(OrderItem item: existingOrderItems){

            if(item.LastModifiedDate <= OrderItem.LastModifiedDate ) { reservedQuantity += item.quantity;}
        }

        Decimal lowestAvailableQuantity = orderItem.Inventory_Tool__r.Current_Inventory_F__c - reservedQuantity;

        return lowestAvailableQuantity;

    }


}