public class OrderItemHelperClass {
    public static Boolean recursion = false;
    static final String LOST = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Lost').getRecordTypeId();
    static final String RE_TURN =Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Returned').getRecordTypeId();
    static final String OUT = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Fulfilled').getRecordTypeId();

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
                    Transaction__c trans = returnTrans(item, LOST,null,diffLost);
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


    public static void handleStatus(List<OrderItem> itemList){
        recursion = true;
        set<Id> orderIdSet = new set<Id>();
        for(orderitem item: itemList){
            orderIdSet.add(item.orderid);
        }

        List<Order> orderListToUpdate = new List<Order>();
        for(Order order: [SELECT Id,Amount_Owed__c,(SELECT Id,Status__c FROM OrderItems WHERE Product2.Type__c = 'Tool') FROM Order WHERE Id IN: orderIdSet]){
            Boolean unconfirmed=false,confirmed=false,partiallyReturned=false,fulfilled=false,cancelled=false,overdue=false,returned=false,closed=false,unpaid=false;
            Boolean isUpdate = false;
            for(OrderItem item: order.OrderItems){
                if('Unconfirmed'.equalsIgnoreCase(item.Status__c) || 'Unavailable'.equalsIgnoreCase(item.Status__c))
                    unconfirmed = true;
                if('confirmed'.equalsIgnoreCase(item.Status__c))
                    confirmed = true;
                if('fulfilled'.equalsIgnoreCase(item.Status__c))
                    fulfilled = true;
                if('cancelled'.equalsIgnoreCase(item.Status__c))
                    cancelled = true;
                if('overdue'.equalsIgnoreCase(item.Status__c))
                    overdue = true;
                if('returned'.equalsIgnoreCase(item.Status__c))
                    returned = true;
                if('closed'.equalsIgnoreCase(item.Status__c))
                    closed = true;
                if('unpaid'.equalsIgnoreCase(item.Status__c))
                    unpaid = true;
                if('Partially Returned'.equalsIgnoreCase(item.Status__c))
                    partiallyReturned = true;
            }

            if(unconfirmed && !confirmed && !fulfilled){
                order.status = 'Unconfirmed';
                isUpdate = true;
            }else if(unconfirmed && confirmed){
                order.status = 'Partially Confirmed';
                isUpdate = true;
            }else if(!unconfirmed && confirmed ){
                order.status = 'Confirmed';
                isUpdate = true;
            }else if(unconfirmed && fulfilled ){
                order.status = 'Fulfilled';
                isUpdate = true;
            }else if(!unconfirmed && !confirmed && fulfilled && !cancelled && !overdue && !returned && !partiallyReturned  ){
                order.status = 'Fulfilled';
                order.Actual_Pickup_Date_Time__c = system.now();
                isUpdate = true;
            }else if(!unconfirmed && !confirmed && !fulfilled && cancelled && !overdue && !returned && !partiallyReturned ){
                order.status = 'Cancelled';
                isUpdate = true;
            }else if( overdue){
                order.status = 'Overdue';
                isUpdate = true;
            }else if(!unconfirmed && !confirmed && !fulfilled && !cancelled && !overdue && returned && !partiallyReturned ){
                order.status = 'Returned';
                if(order.Amount_Owed__c == 0){
                    order.status = 'Closed';
                }else if(order.Amount_Owed__c != 0){
                    order.status = 'Unpaid';
                }
                isUpdate = true;
            }else if(partiallyReturned){
                order.status = 'Partially Returned';
                isUpdate = true;
            }else if(fulfilled && (returned || partiallyReturned )){
                order.status = 'Partially Returned';
                isUpdate = true;
            }
            
            if(isUpdate)
                orderListToUpdate.add(order);
        }

        if(!orderListToUpdate.isEmpty())
            update orderListToUpdate;
    }
}