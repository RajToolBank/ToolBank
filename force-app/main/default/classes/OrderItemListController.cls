public without sharing class OrderItemListController {
    

    @AuraEnabled
    public static List<OrderItem> massDateChangeLowest(String orderItems){
        //try {
            
            system.debug(orderItems);
            list<object> itemList = (list<object>)JSON.deserializeUntyped(orderItems);
            system.debug(itemList);
            List<String> itemIdList = new List<String>();
            set<String> productIdSet = new set<String>();
            List<Date> dateList = new List<Date>();
            Id accountId;
            for(Object item: itemList){
                map<string, object> itemap = (map<string, object>)item;
                itemIdList.add(String.valueOf(itemap.get('id')));
                dateList.add(Date.valueOf((String)itemap.get('retDate')));
                dateList.add(Date.valueOf((String)itemap.get('pickupDate')));
                productIdSet.add((String)itemap.get('product2Id'));
                accountId = (String)itemap.get('accId');
            }
            system.debug(accountId);
            dateList.sort();
            Date minPickDate = dateList[0];
            Date maxReturnDate = dateList[dateList.size()-1];

            List<OrderItem> orderItemList =   [SELECT Id,product2Id,
                                        Product2.Tool_note__c,
                                        product2.name,
                                        LastModifiedDate,
                                        status__c,
                                        Quantity,
                                        Order.Affiliate__c,
                                        Reserved_Quantity__c,
                                        PriceBookEntryId,
                                        Affiliate_Handling_Fee__c,
                                        Inventory_Tool__c,
                                        Inventory_Tool__r.On_Shelf_Quantity_F__c,
                                        Inventory_Tool__r.Current_Inventory_F__c,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE product2Id IN: productIdSet 
                                        AND Order.Affiliate__c =: accountId
                                        AND status__c != 'Returned'
                                        AND (
                                                (Schedule_Pick_Date__c <=: maxReturnDate
                                                    AND Schedule_Return_Date__c >=: minPickDate)
                                                OR Id IN: itemIdList
                                            )
                                        ORDER BY LastModifiedDate ASC];

            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(orderItemList);
            system.debug('orderItemMap :: '+orderItemMap.keySet());
            Map<id, List<OrderItem>> productIdToItemListMap =  new Map<Id, List<OrderItem>>();
            for(OrderItem item: orderItemList){
                if(!itemIdList.contains(item.id)) {
                    if(!productIdToItemListMap.containsKey(item.product2Id))
                        productIdToItemListMap.put(item.product2Id, new List<OrderItem>());
                    productIdToItemListMap.get(item.product2Id).add(item);
                }
            }
            Map<id, Asset> productIdToAssetMap =  new Map<Id, Asset>();
            for(Asset asset: [SELECT Id,Product2Id,Current_Inventory_F__c,On_Shelf_Quantity_F__c FROM Asset WHERE accountId =: accountId and Product2Id IN:productIdSet]){
                productIdToAssetMap.put(asset.Product2Id, asset);
            }
            system.debug(productIdToAssetMap);
            Map<String,Decimal> itemIdToLowest = new map<String, Decimal>();
            List<OrderItem> itemListToReturn = new List<OrderItem>();
            for(Object item: itemList){
                map<string, object> itemap = (map<string, object>)item;
               
                List<OrderItem> orderItemss = productIdToItemListMap.get((String)itemap.get('product2Id'));
                OrderItem orderItem;
                if((String.valueOf(itemap.get('id')) instanceof Id) && orderItemMap.containsKey(String.valueOf(itemap.get('id'))))
                    orderItem = orderItemMap.get((String)itemap.get('id'));//instanceof
                if(orderItem == Null){
                    orderItem = new OrderItem();
                    orderItem.product2 = orderItemss != null && orderItemss.size() >0 ?orderItemss[0].product2:null;
                    orderItem.product2Id = (String)itemap.get('product2Id');
                    orderItem.Order = orderItemss != null && orderItemss.size() >0 ?orderItemss[0].Order:null;
                    orderItem.Quantity = Integer.valueOf(itemap.get('reqQty'));
                    orderItem.Status__c = String.valueOf(itemap.get('status'));
                    System.debug('productIdToAssetMap :: '+productIdToAssetMap.get((String)itemap.get('product2Id')));
                    orderItem.Inventory_Tool__r = productIdToAssetMap.get((String)itemap.get('product2Id'));
                }
                orderItem.Schedule_Pick_Date__c = Date.valueOf((String)itemap.get('pickupDate'));
                orderItem.Schedule_Return_Date__c = Date.valueOf((String)itemap.get('retDate'));
                Decimal lowest = LowestQuantityCalculateClasss.lowestQuantityItemDate(orderItem, DateTime.now(), orderItemss);
                Decimal cQty = (Integer)itemap.get('confirmqty');
                system.debug('cQty :: '+cQty);
                if (cQty > lowest) {
                    itemIdToLowest.put(String.valueOf(itemap.get('id')), lowest); 
                    orderItem.Reserved_Quantity__c =  cQty;
                    orderItem.Lowest_Available_Quantity_For_this_Item__c = lowest;
                    itemListToReturn.add(orderItem); 
                }
            }
            return itemListToReturn;
      //  } catch (Exception e) {
        //    throw new AuraHandledException(e.getMessage());
        //}
    }


    @AuraEnabled
    public static List<OrderItem> getConflictedItems(String itemId, String affilliateId, String product2Id, Date pickupDate, Date returnDate){

        List<String> orderstatus = new List<String>{'Unconfirmed','Partially Confirmed','Confirmed','Fulfilled','Partially Returned','Overdue' };
         
        Map<String, OrderItem> orderToItemMap = new Map<String, OrderItem>();
        for(OrderItem item: [SELECT Id,product2Id,
                                        orderid,
                                        Order__c,
                                        LastModifiedDate,
                                        Quantity,
                                        order.EffectiveDate,
                                        Order.status,
                                        Order.Name,
                                        Order.Account.Name,
                                        Order.OrderNumber,
                                        Order.EndDate,
                                        PriceBookEntryId,
                                        Inventory_Tool__c,
                                        Affiliate_Handling_Fee__c,
                                        Inventory_Tool__r.Current_Inventory_F__c,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Reserved_Quantity__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE product2Id =: product2Id 
                                        AND Schedule_Pick_Date__c <=: returnDate
                                        AND Schedule_Return_Date__c >=: pickupDate
                                        AND Product2.Type__c = 'Tool'
                                        AND Order.Affiliate__c =:affilliateId
                                        AND Order.status IN: orderstatus
                                        AND id !=: itemId
                                        ORDER BY Schedule_Return_Date__c ASC])
        {
            if(!orderToItemMap.containsKey(item.orderid)){
                orderToItemMap.put(item.orderid, item);
            }
            
            orderItem line = orderToItemMap.get(item.orderid);
            if(line.Id != item.Id){
                line.quantity += item.quantity != null? item.quantity:0;
                line.Reserved_Quantity__c += item.Reserved_Quantity__c != null? item.Reserved_Quantity__c:0;
            }
            line.Schedule_Pick_Date__c = item.order.EffectiveDate;
            line.Schedule_Return_Date__c = item.Schedule_Return_Date__c;

        }
        

        return orderToItemMap.values();
    }
}