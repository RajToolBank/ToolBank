public class ReturnOrderController {

    @AuraEnabled(cacheable = true)
    public static OrderDetails getOrderItems(String orderId) {
        return getOrderItemsDirect(orderId);
    }

    @AuraEnabled
    public static OrderDetails getOrderItemsDirect(String orderId) {
        try {

            OrderDetails orderDetail = new OrderDetails();
            orderDetail.orderItems = new List<OrderItemDetails>();
            orderDetail.returnOrderItems = new List<OrderItemDetails>();
            for(Order ord: [SELECT Id, name,Account.Name,Desired_Pickup_Date__c,
                    Desired_Pickup_Time__c,OrderNumber,CreatedDate,EffectiveDate,
                    Scheduled_Pickup_Time__c,Schedule_Return_Date__c,EndDate,Status,
                    (SELECT Id,
                    Product2.Name,
                    Tool_Handling_Fee_Per_Item__c,
                    Status__c,
                    Check_In_Quantity__c,
                    Product2.Tool_Note__c,
                    Check_Out_Quantity__c,
                    Total_Check_In_Quantity__c,
                    Actual_Return_Date__c,
                    Lost__c,
                    late_Fee__c,
                    Damaged__c,
                    Inventory_Tool__c,
                    UnitPrice,
                    Product2Id,
                    PricebookEntryId,
                    Affiliate_Handling_Fee__c,
                    Requested_Borrowing_Period__c,
                    Schedule_Return_Date__c
                    FROM OrderItems 
                    WHERE Product2.Type__c ='Tool'
                    AND Status__c != 'Unavailable'
                    ORDER BY Product2.Name ) 
                    FROM ORDER WHERE Id =: orderId]){
                orderDetail.order = ord;
                if( !'Fulfilled'.equalsIgnoreCase(ord.status) && !'Partially Returned'.equalsIgnoreCase(ord.status) && !'Overdue'.equalsIgnoreCase(ord.status)){
                    orderDetail.readOnly = true;
                }
                for(OrderItem item: ord.OrderItems){
                    OrderItemDetails orditem = new OrderItemDetails();
                    orditem.orderitem = item;
                    Decimal borrowed = item.Check_Out_Quantity__c!= null?item.Check_Out_Quantity__c:0;
                    Decimal totalReturned = item.Total_Check_In_Quantity__c!= null?item.Total_Check_In_Quantity__c:0;
                    Decimal lost = item.Lost__c!= null?item.Lost__c:0;
                    orditem.stillOut = Integer.valueOf(borrowed-totalReturned);
                    orditem.lost = (item.unitPrice*lost).setScale(2);
                    //if(item.Schedule_Return_Date__c < Date.today())
                        orditem.late = item.late_Fee__c.setScale(2);
                   // else orditem.late =0;
                    orditem.total = (orditem.lost + orditem.late).setScale(2);
                    orditem.fixed = item.status__c;
                    orditem.isReturned = item.status__c == 'Returned'?true:false;

                    if(item.status__c == 'Returned')
                        orderDetail.returnOrderItems.add(orditem);
                    else orderDetail.orderItems.add(orditem);

                }
            }
            return orderDetail;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveOrder(String itemsList){
       // try {
            system.debug(itemsList);
            List<Object> ordItemList = (List<Object>) json.deserializeUntyped(itemsList);
            list<OrderItem> orderItemList = new List<orderItem>();
            list<Date> orderItemReturnDateList = new List<Date>();
            String returnedBy;
            String orderid;
            Set<String> orderToolIdsSet = new Set<String>();
            
            for(Object obj:ordItemList){
                Map<String, Object> item = (Map<String, Object>)obj;
                OrderItem orderItem = new OrderItem();
                String itemId = (string)item.get('Id');
                returnedBy = (String)item.get('returnedBy');
                orderid = (string)item.get('orderid');
                orderToolIdsSet.add(itemId);
                if(itemId != '2'){
                    orderItem.id = itemId;
                }else{
                    orderItem.Inventory_Tool__c  =(string)item.get('assetid');   
                    orderItem.unitPrice =Decimal.valueOf((String)item.get('unitPrice'));
                    //product2id:product2id,
                    
                    orderitem.orderid = (string)item.get('orderid');
                    orderItem.pricebookEntryId = (string)item.get('pbeid');
                    orderItem.Affiliate_Handling_Fee__c = Decimal.valueOf((String)item.get('affiliatefee'));
                    
                }

                if(item.containsKey('borrowed')){
                    orderitem.quantity = Decimal.valueOf((Integer)item.get('borrowed'));
                    orderitem.Reserved_Quantity__c = Decimal.valueOf((Integer)item.get('borrowed'));
                }

                //OrderItem/returnDate:returnDate,
                Decimal lost = Decimal.valueOf((Integer)item.get('lost'));
                Decimal damaged = Decimal.valueOf( (Integer)item.get('damaged'));
                Decimal returnqty = Decimal.valueOf((Integer)item.get('returnqty'));

                if(lost != Null && lost !=0)
                    orderItem.Lost__c= lost;
                if(damaged != Null && damaged !=0)
                    orderItem.damaged__c =damaged;
                if(returnqty != Null && returnqty !=0)
                    orderItem.Check_In_Quantity__c = returnqty;

                orderItem.Requested_Borrowing_Period__c = (string)item.get('borrowedPeriod');

                orderItem.status__c = (String)item.get('status');

                if('Returned'.equalsIgnoreCase(OrderItem.status__c))
                    orderItem.Actual_Return_Date__c = system.today();
                orderItem.Schedule_Return_Date__c = Date.valueOf((String)item.get('returnDate'));
                orderItemReturnDateList.add(orderItem.Schedule_Return_Date__c);
                orderItem.Schedule_Pick_Date__c = Date.valueOf((String)item.get('EffectiveDate'));
                //basefee:basefee,
                Decimal borrowed = Decimal.valueOf((Integer)item.get('borrowed'));
                if(borrowed != Null && borrowed !=0)
                    OrderItem.Check_Out_Quantity__c= borrowed;

                orderItemList.add(orderitem);
            }
            

            if(String.isNotBlank(orderid) ){
                Order order = new order( id=orderid);
                if( String.isNotBlank(returnedBy))
                    order.Tools_Returned_By__c=returnedBy;
                if(orderItemReturnDateList.size()>0){
                    orderItemReturnDateList.sort();
                    order.EndDate = orderItemReturnDateList[0];
                }
                ByPassValidations.ordStatusValidation = true;
                update order;
            }
            ByPassValidations.ordItemPriceAndQtyValidation = true;
            if(!orderItemList.isEmpty())
                upsert orderItemList;

            return 'success';
    }

    public class OrderDetails{

        @AuraEnabled
        public Order order;
        @AuraEnabled
        public Boolean readOnly;
        @AuraEnabled
        public List<OrderItemDetails> orderItems;
        @AuraEnabled
        public List<OrderItemDetails> returnOrderItems;
    }

    public class OrderItemDetails{

       
        @AuraEnabled
        public OrderItem orderItem;
        @AuraEnabled
        public Integer stillOut;
        @AuraEnabled
        public Decimal lost;
        @AuraEnabled
        public Decimal late;
        @AuraEnabled
        public Decimal total;
        @AuraEnabled
        public String fixed;
        @AuraEnabled
        public Boolean isReturned;


    }
}