public class ConfirmOrderPageController {
    
    @AuraEnabled(cacheable=true)
    public static OrderDetails getOrderDetails(String recordId){

        return getOrderDetailsDirect(recordId);
    }


    @AuraEnabled
    public static OrderDetails getOrderDetailsDirect(String recordId){

        List<Order> order = [SELECT Id,Account.name,Affiliate__c,Status,Requested_Borrowing_Period__c,createdDate,name,Schedule_Return_Date__c, OrderNumber,Desired_Pickup_Date__c,Desired_Pickup_Time__c,EffectiveDate,Scheduled_Pickup_Time__c FROM Order WHERE Id =: recordId];
        OrderDetails OrderDetails = new OrderDetails();
        OrderDetails.order = order[0];
        List<OrderItem> OrderItemList =LowestQuantityCalculateClasss.lowestQuantityOrder3(order);
        if(OrderItemList != Null && OrderItemList.size()>0){
            
            Map<Decimal, list<OrderItem>> availablesorting = new map<Decimal, list<OrderItem>>();
            List<Decimal> sortList = new List<Decimal>();
        // system.debug(OrderItemList.size());

            for(OrderItem item: OrderItemList){
                Decimal diff = item.Lowest_Available_Quantity_For_this_Item__c - item.Reserved_Quantity__c;
                if(!sortList.contains(diff))
                    sortList.add(diff);

                if(!availablesorting.containsKey(diff))
                    availablesorting.put(diff, new list<OrderItem>());
                    
                availablesorting.get(diff).add(item);
                system.debug(item);
            }
        system.debug(availablesorting);
            sortList.sort();
           
            OrderDetails.orderItemList = new List<OrderItem>();
            for(Decimal diff: sortList){
                OrderDetails.orderItemList.addAll(availablesorting.get(diff));
            }
            system.debug(OrderDetails.orderItemList.size());

        }
            return OrderDetails;
        
    }

    @AuraEnabled(cacheable=true)
    public static List<AvailableProducts> getTools(List<String> toolIds, String accid, String searchString,String category){
        system.debug(toolIds);
        //String accid = [SELECT Id, Contact.Account.parentId FROM User WHERE Id =: UserInfo.getUserId()].Contact.Account.parentId;
        system.debug(accId);

        if(accId == Null){
            accId = '0010200000Gdf2yAAB';
        }

        List<Asset> assetList;
        if(String.isBlank(searchString) && String.isBlank(category)){
            assetList = [SELECT Id,Affiliate_Handling_Fee__c,
                        Product2Id,
                        price 
                        FROM Asset 
                        WHERE AccountId =: accid
                        AND Unlisted_Item__c = false
                        AND Product2Id  NOT IN: toolIds
                        AND Product2.Type__c = 'Tool'
                        AND (Quantity != Null 
                        OR Quantity != 0)];
        }else{
            if(String.isNotBlank(searchString))
                searchString = '%'+searchString+'%';
            if(String.isBlank(category) && String.isNotBlank(searchString)){
                assetList = [SELECT Id,Affiliate_Handling_Fee__c,
                            Product2Id,
                            price 
                            FROM Asset 
                            WHERE AccountId =: accid
                            AND Unlisted_Item__c = false
                            AND (Product2.name like: searchString
                            OR Product2.productCode like:searchString
                            OR Product2.Tool_Note__c like:searchString)
                            AND Product2Id  NOT IN: toolIds
                            AND Product2.Type__c = 'Tool'
                            AND (Quantity != Null 
                            OR Quantity != 0)];
            }
            else if(String.isNotBlank(category) && String.isBlank(searchString)){
                assetList = [SELECT Id,Affiliate_Handling_Fee__c,
                            Product2Id,
                            price 
                            FROM Asset 
                            WHERE AccountId =: accid
                            AND Product2.Family =: category
                            AND Unlisted_Item__c = false
                            AND Product2Id  NOT IN: toolIds
                            AND Product2.Type__c = 'Tool'
                            AND (Quantity != Null 
                            OR Quantity != 0)];
            }
            else if(String.isNotBlank(category) && String.isNotBlank(searchString)){
                assetList = [SELECT Id,Affiliate_Handling_Fee__c,
                            Product2Id,
                            price 
                            FROM Asset 
                            WHERE AccountId =: accid
                            AND Unlisted_Item__c = false
                            AND (Product2.name like: searchString
                            OR Product2.productCode like:searchString
                            OR Product2.Tool_Note__c like:searchString)
                            AND product2.Family =: category
                            AND Product2Id  NOT IN: toolIds
                            AND Product2.Type__c = 'Tool'
                            AND (Quantity != Null 
                            OR Quantity != 0)];
            }
        }

        Set<Id> productidSet = new Set<Id>();
        Map<id, Asset> productIdToAssetMap = new map<Id, Asset>();
        for(Asset asset:  assetList){
            productidSet.add(asset.product2Id);
            productIdToAssetMap.put(asset.Product2Id, asset);
        }
        
        List<AvailableProducts> availableProducts = new List<AvailableProducts>();
        for(PriceBookEntry pbe: [SELECT Id,
                                        Product2Id,
                                        UnitPrice,
                                        Product2.Tool_Note__c, 
                                        Product2.Sub_Category__c,
                                        Product2.Name, 
                                        Product2.Family 
                                        FROM PriceBookEntry 
                                        WHERE Product2Id IN: productidSet]){
            AvailableProducts availableProduct = new AvailableProducts();
            availableProduct.Id = pbe.id;
            availableProduct.Product2Id =pbe.Product2Id;
            availableProduct.UnitPrice =pbe.UnitPrice;
            availableProduct.ToolNote= pbe.Product2.Tool_Note__c;
            availableProduct.SubCategory=pbe.Product2.Sub_Category__c;
            availableProduct.Name=pbe.Product2.Name;
            availableProduct.Family= pbe.Product2.Family;
            availableProduct.handlingFee = productIdToAssetMap.get(pbe.product2Id).Affiliate_Handling_Fee__c;
            availableProduct.AssetId = productIdToAssetMap.get(pbe.product2Id).Id;
            availableProducts.add(availableProduct);
        }
                                        
        return availableProducts;
    }

    @AuraEnabled
    public static Decimal singleItemLowestQuantity(String itemId, String product2Id, Date pickupDate, Date returnDate){

        system.debug('itemId '+itemId +' product2Id '+product2Id+' pickupDate '+pickupDate+' returnDate '+returnDate);
        List<OrderItem> allItemList =   [SELECT Id,product2Id,
                                        LastModifiedDate,Quantity,
                                        Affiliate_Handling_Fee__c,
                                        PriceBookEntryId,
                                        Inventory_Tool__c,
                                        Inventory_Tool__r.Current_Inventory_F__c,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Reserved_Quantity__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE (product2Id =: product2Id 
                                        AND Schedule_Pick_Date__c <=: returnDate
                                        AND Schedule_Return_Date__c >=: pickupDate)
                                        OR Id =: itemId
                                        ORDER BY LastModifiedDate ASC];
        Map<Id, OrderItem> itemMap = new Map<Id, OrderItem>(allItemList);

        orderItem orderItem = itemMap.remove(itemId);
        orderItem.Schedule_Pick_Date__c = pickupDate;
        orderItem.Schedule_Return_Date__c = returnDate;
        system.debug('orderItem :: '+orderItem);
        system.debug('itemMap :: '+itemMap);

        return LowestQuantityCalculateClasss.lowestQuantityItemDate(orderItem, DateTime.now(), itemMap.values());
    }

    @AuraEnabled
    public static Map<String,Decimal> massDateChangeLowest(String orderItems){
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
                                        LastModifiedDate,Quantity,
                                        PriceBookEntryId,
                                        Affiliate_Handling_Fee__c,
                                        Inventory_Tool__c,
                                        Inventory_Tool__r.Current_Inventory_F__c,
                                        Lowest_Available_Quantity_For_this_Item__c,
                                        Reserved_Quantity__c,
                                        Schedule_Pick_Date__c,
                                        Schedule_Return_Date__c 
                                        FROM OrderItem 
                                        WHERE product2Id IN: productIdSet 
                                        AND Order.Affiliate__c =: accountId
                                        AND (Id  IN: itemIdList
                                        OR (Schedule_Pick_Date__c <=: maxReturnDate
                                        AND Schedule_Return_Date__c >=: minPickDate))
                                        ORDER BY LastModifiedDate ASC];
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(orderItemList);
            Map<id, List<OrderItem>> productIdToItemListMap =  new Map<Id, List<OrderItem>>();
            for(OrderItem item: orderItemList){
                if(!itemIdList.contains(item.id)){
                    if(!productIdToItemListMap.containsKey(item.product2Id))
                        productIdToItemListMap.put(item.product2Id, new List<OrderItem>());

                    productIdToItemListMap.get(item.product2Id).add(item);
                }
            }
            Map<id, Asset> productIdToAssetMap =  new Map<Id, Asset>();
            for(Asset asset: [SELECT Id,Product2Id,Current_Inventory_F__c FROM Asset WHERE accountId =: accountId and Product2Id IN:productIdSet]){
                productIdToAssetMap.put(asset.Product2Id, asset);
            }
            system.debug(productIdToAssetMap);
            Map<String,Decimal> itemIdToLowest = new map<String, Decimal>();
            for(Object item: itemList){
                map<string, object> itemap = (map<string, object>)item;
                List<OrderItem> orderItemss = productIdToItemListMap.get((String)itemap.get('product2Id'));
                OrderItem orderItem;
                system.debug(productIdToAssetMap.get((String)itemap.get('product2Id')));
                if((String.valueOf(itemap.get('id')) instanceof Id) && orderItemMap.containsKey(String.valueOf(itemap.get('id'))))
                    orderItem = orderItemMap.get((String)itemap.get('id'));//instanceof
                if(orderItem == Null){
                    orderItem = new OrderItem();
                    //orderItem.Id = (String)itemap.get('id');
                    orderItem.Inventory_Tool__r = productIdToAssetMap.get((String)itemap.get('product2Id'));
                }
                system.debug(orderItem);
                system.debug(orderItemss);
                orderItem.Schedule_Pick_Date__c = Date.valueOf((String)itemap.get('pickupDate'));
                orderItem.Schedule_Return_Date__c = Date.valueOf((String)itemap.get('retDate'));
                Decimal lowest = LowestQuantityCalculateClasss.lowestQuantityItemDate(orderItem, DateTime.now(), orderItemss);
                itemIdToLowest.put(String.valueOf(itemap.get('id')), lowest);   
            }
            return itemIdToLowest;
      //  } catch (Exception e) {
        //    throw new AuraHandledException(e.getMessage());
        //}
    }

    @AuraEnabled
    public static string saveOrder(String orderNitemsDetails, String orderItemToDelete){
        system.debug(orderNitemsDetails);
        Map<String, object> orderAndItemDetails = (Map<String, object>)JSON.deserializeUntyped(orderNitemsDetails);
        Map<String, Object> order = (Map<String, Object>)orderAndItemDetails.get('order');
        
        if(String.isNotBlank(orderItemToDelete)){
            List<object> ItemToDelete = (List<object>)JSON.deserializeUntyped(orderItemToDelete);
            List<OrderItem> toolsToDelete = new List<OrderItem>();
            for(Object obj: ItemToDelete){
                String id = (String)obj;
                if(id.startsWith('802')){
                    toolsToDelete.add(new OrderItem(Id=id));
                }
            }
            if(!toolsToDelete.isEmpty())
                delete toolsToDelete;
        }

        update new order(
            id= (Id)order.get('Id'),
            EffectiveDate = Date.valueOf((String)order.get('EffectiveDate')),
            name =  (String)order.get('Name'),
            status = (String)order.get('Status'),
            pricebook2Id = '01sA0000000PfKSIA0'
        );
        
        list<OrderItem> orderitems = new List<OrderItem>();
        for(object obj: (List<Object>)orderAndItemDetails.get('orderItems')){
            Map<String, object> item = (Map<String, object>)obj;
            system.debug(item);
            OrderItem orderitem = new OrderItem();
            if(((String) item.get('Id')).startsWith('802')){
                orderItem.id = (String) item.get('Id');
            }else{
                orderItem.orderid= (String)order.get('Id');
                orderItem.PricebookEntryId = (String)item.get('pbeId');
                orderitem.UnitPrice = Decimal.valueOf((String)item.get('unitprice'));
                orderItem.Inventory_Tool__c = (String)item.get('assetid');
            }
            orderItem.quantity =Decimal.valueOf((String) item.get('quantity'));
            orderItem.Affiliate_Handling_Fee__c =Decimal.valueOf((String) item.get('affiliateFee'));
            orderItem.Requested_Borrowing_Period__c = (String) item.get('week');
            orderItem.Reserved_Quantity__c=Decimal.valueOf((String) item.get('reserv'));
            orderItem.Schedule_return_Date__c = Date.valueOf((String)item.get('retDate'));
            orderItem.Schedule_Pick_Date__c = Date.valueOf((String)item.get('pickdate'));
            orderItem.Status__c = (String) item.get('status');
            system.debug(orderitem);
            if((String) item.get('status') == 'Fulfilled')
                orderItem.Check_Out_Quantity__c=Decimal.valueOf((String) item.get('reserv'));

            orderitems.add(orderitem);
        }

        upsert orderitems;

        return 'success';
    }

    public class OrderDetails{
        @AuraEnabled
        public Order order;
        @AuraEnabled
        public List<OrderItem> orderItemList;
    }

    public class AvailableProducts{
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String  Product2Id;
        @AuraEnabled
        public Decimal UnitPrice;
        @AuraEnabled
        public String ToolNote;
        @AuraEnabled 
        public String  SubCategory;
        @AuraEnabled
        public String Name;
        @AuraEnabled 
        public String Family;
        @AuraEnabled 
        public String AssetId;  
        @AuraEnabled 
        public Decimal handlingFee;

    }
}
