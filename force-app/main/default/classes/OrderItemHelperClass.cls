public class OrderItemHelperClass {
    public static Boolean recursion = false;
    public static Boolean recursionUpdate = false;
    static final String LOST = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Lost').getRecordTypeId();
    static final String RE_TURN =Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Returned').getRecordTypeId();
    static final String OUT = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Fulfilled').getRecordTypeId();

    public static void createTransactionOnInsert(List<OrderItem> itemList){
        List<Transaction__c> transactionList = new List<Transaction__c>();
        for(OrderItem tool: itemList){
            String newStatus = tool.status__c;
            Boolean isFullfilled = 'Fulfilled'.equalsIgnoreCase(newStatus);
            Boolean isReturned = 'Returned'.equalsIgnoreCase(newStatus);
            Boolean isDamaged = 'Damaged'.equalsIgnoreCase(newStatus);
            Boolean isLost = 'Lost'.equalsIgnoreCase(newStatus);
            Boolean isPartiallyReturned = 'Partially Returned'.equalsIgnoreCase(newStatus);
            if(isFullfilled || isReturned || isDamaged || isLost || isPartiallyReturned){
                if(tool.Check_In_Quantity__c != null && tool.Check_In_Quantity__c != 0){
                    Transaction__c trans = returnTrans(tool, RE_TURN,null,tool.Check_In_Quantity__c);
                    transactionList.add(trans);
                }
                
                if(tool.Lost__c != null && tool.Lost__c != 0){
                    Transaction__c trans = returnTrans(tool, LOST,'Lost - Return',tool.Lost__c);
                    transactionList.add(trans);
                }
                
                if(tool.Damaged__c != null && tool.Damaged__c != 0){
                    Transaction__c trans = returnTrans(tool, RE_TURN,'Damaged',tool.Damaged__c);
                    transactionList.add(trans);
                }
                
                if(tool.Check_Out_Quantity__c != null && tool.Check_Out_Quantity__c != 0){
                    Transaction__c trans = returnTrans(tool, OUT,null,tool.Check_Out_Quantity__c);
                    transactionList.add(trans);
                }
            }
        }

        if(!transactionList.isEmpty()){
            insert transactionList;
        }
    }
    public static void createTransaction(List<OrderItem> itemList, Map<Id, OrderItem> oldMap){

        List<Transaction__c> transactionList = new List<Transaction__c>();
        for(OrderItem item: itemList){
            OrderItem oldItem = oldMap.get(item.Id);
            String oldStatus, newStatus;
            newStatus = item.status__c;
            oldStatus = oldItem.status__c;  
            Boolean isCheckInSame = (item.Check_In_Quantity__c == oldItem.Check_In_Quantity__c);
            Boolean isCheckOutSame = (item.Check_Out_Quantity__c ==  oldItem.Check_Out_Quantity__c);
            Boolean isLostSame = (item.Lost__c == oldItem.Lost__c);
            Boolean isDamangeSame = (item.Damaged__c == oldItem.Damaged__c);
            Boolean isFullfilled = 'Fulfilled'.equalsIgnoreCase(newStatus);
            Boolean isReturned = 'Returned'.equalsIgnoreCase(newStatus);
            Boolean isDamaged = 'Damaged'.equalsIgnoreCase(newStatus);
            Boolean isLost = 'Lost'.equalsIgnoreCase(newStatus);
            Boolean isPartiallyReturned = 'Partially Returned'.equalsIgnoreCase(newStatus);
            Decimal checkInNew = item.Check_In_Quantity__c != Null?item.Check_In_Quantity__c:0;
            Decimal checkInOld = oldItem.Check_In_Quantity__c != Null?oldItem.Check_In_Quantity__c:0;
            Decimal lostNew = item.Lost__c != Null?item.Lost__c:0;
            Decimal lostOld = oldItem.Lost__c != Null?oldItem.Lost__c:0;
            Decimal damagedNew = item.Damaged__c != Null?item.Damaged__c:0;
            Decimal damagedOld = oldItem.Damaged__c != Null?oldItem.Damaged__c:0;
            Decimal checkOutNew = item.Check_Out_Quantity__c != Null?item.Check_Out_Quantity__c:0;
            Decimal checkOutOld = oldItem.Check_Out_Quantity__c != Null?oldItem.Check_Out_Quantity__c:0;
           system.debug('isCheckOutSame :: '+ isCheckOutSame);
            if(!isCheckOutSame ){ //&& isFullfilled
                Decimal diff = checkOutNew - checkOutOld;
                system.debug('diff :: '+ diff);
                if(diff != 0){
                    Transaction__c trans = returnTrans(item,OUT,null,diff);
                    transactionList.add(trans);
                }
            }
            
            if((!isCheckInSame || !isLostSame || !isDamangeSame) ){ //&& (isReturned || isPartiallyReturned || isDamaged || isLost)

                Decimal diff = checkInNew - checkInOld;
                if(diff != 0){
                    Transaction__c trans = returnTrans(item, RE_TURN,null,diff);
                    transactionList.add(trans);
                }

                Decimal diffLost = lostNew - lostOld;
                if(diffLost != 0){
                    Transaction__c trans = returnTrans(item, LOST,'Lost - Return',diffLost);
                    transactionList.add(trans);
                }

                Decimal diffDamaged = damagedNew - damagedOld;
                if(diffDamaged != 0){
                    Transaction__c trans = returnTrans(item, RE_TURN,'Damaged',diffDamaged);
                    transactionList.add(trans);
                } 

            }


        }

        if(!transactionList.isEmpty()){
            insert transactionList;
        }
    }

    static Transaction__c returnTrans(OrderItem item, String recordTypeId, String subType, Decimal quantity){
        Transaction__c trans = new Transaction__c();
        trans.Inventory__c = item.Inventory_Tool__c;
        trans.Order_Product__c = item.Id;
        trans.recordTypeId = recordTypeId;
        trans.sub_type__c = subType;
        trans.quantity__c = quantity;

        return trans;
    }


    public static void handleStatus(List<OrderItem> itemList,Map<Id, OrderItem> oldMap){
        recursion = true;
        if(System.trigger.isUpdate)
            recursionUpdate = true;
        
        set<Id> orderIdSet = new set<Id>();
        for(orderitem item: itemList){
            if(oldMap == Null || item.status__c != oldMap.get(item.Id).status__c || System.trigger.isDelete)
                orderIdSet.add(item.orderid);
        }

        List<Order> orderListToUpdate = new List<Order>();
        for(Order order:    [SELECT Id,Amount_Owed__c,Amount_Paid__c,Status,
                            (SELECT Id,Total_Fees__c,isDeleted,TotalPrice,Status__c,Product2.Type__c FROM OrderItems WHERE isDeleted = false AND Status__c != 'Unavailable' ),
                            (SELECT Id,Amount__c FROM Payments_by_Members__r)
                            FROM Order WHERE Id IN: orderIdSet AND dataloader__c = false]) //WHERE Product2.Type__c = 'Tool'
        {
            Boolean unconfirmed=false,unavailable=false,confirmed=false,partiallyReturned=false,fulfilled=false,cancelled=false,overdue=false,returned=false,closed=false,unpaid=false;
            Boolean isUpdate = false;
            String orderStatus = order.status;
            Decimal totalAmount = 0.0;
            for(OrderItem item: order.OrderItems){
                if(item.Product2.Type__c == 'Tool'){
                        totalAmount += item.Total_Fees__c;
                    if('Unconfirmed'.equalsIgnoreCase(item.Status__c) || ('Unavailable'.equalsIgnoreCase(item.Status__c) && ('Unconfirmed'.equalsIgnoreCase(orderStatus) || 'confirmed'.equalsIgnoreCase(orderStatus) || 'Partially Confirmed'.equalsIgnoreCase(orderStatus)) ))
                        unconfirmed = true;
                    else if('Unavailable'.equalsIgnoreCase(item.Status__c) && 'fulfilled'.equalsIgnoreCase(orderStatus)){
                        returned = true;
                        unavailable=true;
                    } else if('confirmed'.equalsIgnoreCase(item.Status__c))
                        confirmed = true;
                    else if('fulfilled'.equalsIgnoreCase(item.Status__c))
                        fulfilled = true;
                    else if('cancelled'.equalsIgnoreCase(item.Status__c))
                        cancelled = true;
                    else if('overdue'.equalsIgnoreCase(item.Status__c))
                        overdue = true;
                    else if('returned'.equalsIgnoreCase(item.Status__c))
                        returned = true;
                    else if('closed'.equalsIgnoreCase(item.Status__c))
                        closed = true;
                    else if('unpaid'.equalsIgnoreCase(item.Status__c))
                        unpaid = true;
                    else if('Partially Returned'.equalsIgnoreCase(item.Status__c))
                        partiallyReturned = true;
                }else{
                    totalAmount +=item.TotalPrice;
                }
            }
            Order orderObje =new Order();
            orderObje.Id = order.Id;
            Decimal amountPaid = 0.00;
            for(Payments_TB__c payment: order.Payments_by_Members__r){
                amountPaid += payment.Amount__c;
            }

            Decimal owedAmount = totalAmount - amountPaid;

            if(unconfirmed && !confirmed && !fulfilled && !unavailable){
                orderObje.status = 'Unconfirmed';
                isUpdate = true;
            }else if(unconfirmed && confirmed){
                orderObje.status = 'Partially Confirmed';
                isUpdate = true;
            }else if(!unconfirmed && confirmed ){
                orderObje.status = 'Confirmed';
                isUpdate = true;
            }else if(unconfirmed && fulfilled ){
                orderObje.status = 'Fulfilled';
                isUpdate = true;
            }else if(!unconfirmed && !confirmed && fulfilled && !cancelled && !overdue && !returned && !partiallyReturned ){
                if( orderStatus != 'Fulfilled'){
                    orderObje.status = 'Fulfilled';
                    orderObje.Actual_Pickup_Date_Time__c = system.now();
                    isUpdate = true;
                }
            }else if(!unconfirmed && !confirmed && !fulfilled && cancelled && !overdue && !returned && !partiallyReturned ){
                orderObje.status = 'Cancelled';
                isUpdate = true;
            }else if( overdue){
                orderObje.status = 'Overdue';
                isUpdate = true;
            }else if(!unconfirmed && !confirmed && !fulfilled && !cancelled && !overdue && returned && !partiallyReturned ){
                orderObje.status = 'Returned';
                if(owedAmount > 0){
                    orderObje.status = 'Unpaid';
                }else if(owedAmount == 0){
                    orderObje.status = 'Closed';
                }
                isUpdate = true;
            }else if(partiallyReturned){
                orderObje.status = 'Partially Returned';
                isUpdate = true;
            }else if(fulfilled && (returned || partiallyReturned )){
                orderObje.status = 'Partially Returned';
                isUpdate = true;
            }else{
                if(owedAmount >= 0){
                    orderObje.status = 'Unpaid';
                    isUpdate = true;
                }
                
            }
            if(isUpdate)
                orderListToUpdate.add(orderObje);
        }

        if(!orderListToUpdate.isEmpty()){
            ByPassValidations.ordStatusValidation = true;
            update orderListToUpdate;
        }
    }


    public static void quantityAndPriceValidation(List<OrderItem> itemList, Map<Id, OrderItem> oldMap){

        for(OrderItem item: itemList){
            Decimal newQty = item.quantity;
            Decimal oldQty = oldMap.get(item.Id).quantity;
            Decimal newPrice = item.UnitPrice;
            Decimal oldPrice = oldMap.get(item.Id).UnitPrice;
            String currentUserProfileId = Userinfo.getProfileId();
            Trigger_Validation__c mc = Trigger_Validation__c.getInstance(currentUserProfileId);
            Boolean isNotAllowed = (mc == null || (mc != null && !mc.Active__c));
            if(newQty != oldQty && !ByPassValidations.ordItemPriceAndQtyValidation && isNotAllowed){
                item.addError(' Insufficient Permissions.');
            }else if(newPrice != oldPrice && !ByPassValidations.ordItemPriceAndQtyValidation && isNotAllowed){
                item.addError(' Insufficient Permissions.');
            }
        }
    }
}