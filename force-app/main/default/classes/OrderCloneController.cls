public without sharing class OrderCloneController {
    public static String affiliateId;
    @AuraEnabled
    public static String cloneOrder(Id originalOrderId, Date pickUpDate, String pickUpTime, String borrowingPeriod) {
        // Clone Order
        String returnOrderId = '';
        try {
            Order originalOrder = [SELECT AccountId,Account_Balance__c,Actual_Pickup_Date_Time__c,Actual_Pickup_Quarter__c,Affiliate_Phone__c,
                                   Affiliate__c,Agency_Contact_Merge__c,Agency_Name_Merge__c,Amount_Owed__c,Amount_Paid__c,Areas_Of_Impact__c,Available_Credits__c,
                                   BillingAddress,BillingCity,BillingCountry,BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,
                                   BillingState,BillingStreet,BillToContactId,Cleaning_Fees__c,Cleaning_R__c,ContactCustom__c,Contact_Email_Legacy__c,
                                   Contact_Email__c,Contact_Name_Legacy__c,Contact_Phone_Legacy__c,Contact_Phone__c,Corporation_Name__c,Created_Date_Original__c,
                                   curEmail__c,Current_Date__c,Days_till_Overdue_Email__c,Days_to_Return__c,Delivery_Address__c,Delivery_Info__c,
                                   Delivery_R_Fee__c,Deposit_R__c,Deposit__c,Desired_Pickup_Date__c,Desired_Pickup_Time__c,Disaster_Name__c,
                                   Earliest_scheduled_return_date__c,EffectiveDate,EndDate,Extend_Appointment__c,Extension_Fee__c,Extension_Requested__c,
                                   External_ID__c,Final_Price__c,Hours_Average_Volunteer_is_on_Site__c,If_Yes_How_Many_Homes__c,Initial_Fees__c,Late_Fee__c,
                                   Lfnt_Order_Number__c,Lost_R_Fee__c,Membership_R_Fee__c,Member_Agency_Status__c,Name,Number_of_Attendees__c,Number_Of_Projects__c,
                                   Number_of_Volunteers__c,OrderID_LFNT_ExternalID__c,OrderId_Orginal__c,Order_Fulfill_Date__c,
                                   Order_Org_Email__c,Order_Paid__c,Order_Scheduler__c,Other_R__c,Other__c,Overdue_Send_Email_Date__c,OwnerId,
                                   People_Directly_Served__c,People_Indirectly_Impacted__c,Pickup_Approved__c,Pickup_Delivery_Location__c,Pricebook2Id,
                                   Project_Type__c,Project_Venue__c,RecordTypeId,Replacement_Cost__c,Requested_Borrowing_Period__c,Scheduled_Pickup_Time__c,
                                   Schedule_PickUp_Date_F__c,Schedule_Return_Date__c,Serving_50_of_Low_Income_People__c,Signed_PDF_Name__c,Staff_on_this_Project__c,
                                   StatusCode,Time_Slot__c,Tools_Returned_By__c,TotalAmount,Total_Amount__c,Total_Handling_Fees__c,
                                   Total_Late_Fee__c,Total_Project_Volunteer_Hours__c,Total_Retail_Amount__c,Type,Volunteer_Source_Migration__c,Volunteer_Source__c,
                                   Waived_External_Sponsor__c,Waived_Forgiven__c,Waived_Internal_Promotion__c,Waived_Internal_Sponsor__c,Waived_Retroaction__c,
                                   Waived__c FROM Order WHERE Id = :originalOrderId Limit 1];
            affiliateId = originalOrder.Affiliate__c;
            Order clonedOrder = originalOrder.clone(false,false,false,false);
            clonedOrder.Actual_Pickup_Date_Time__c = Null;
            clonedOrder.Desired_Pickup_Date__c = pickUpDate;
            clonedOrder.EffectiveDate = pickUpDate;
            clonedOrder.Desired_Pickup_Time__c = pickUpTime;
            clonedOrder.Requested_Borrowing_Period__c = borrowingPeriod;
            Integer num = 0;
            if(!String.isBlank(borrowingPeriod)) {
                String invalidNumbers = '[^0-9]';  
                num = Integer.valueOf(borrowingPeriod.replaceAll(invalidNumbers, ''));
                system.debug( 'num - ' + num);
            }
            clonedOrder.Schedule_Return_Date__c = pickUpDate.addDays(num*7);
            clonedOrder.EndDate = pickUpDate.addDays(num*7);
            clonedOrder.Name = clonedOrder.Name+'_cloned';
            clonedOrder.Status = 'Unconfirmed';
            clonedOrder.Order_Clone_From__c = originalOrderId;
            clonedOrder.Dataloader__c = false;
            insert clonedOrder;
            List<OrderItem> ordItemList = new List<OrderItem>();
            for(Orderitem ordItem :[Select AvailableQuantity, EndDate, Description, ListPrice, OriginalOrderItemId, Product2Id, PricebookEntryId, Quantity, ServiceDate,
                                    UnitPrice, PricebookEntry.UnitPrice, Affiliate_Handling_Fee__c, Borrowing_Duration_Integer_Legacy__c, Category__c,
                                    Create_Date_Order_Item__c, Inventory_Tool__c,
                                    Overdue_legacy__c, Requested_Borrowing_Period__c, Retail_Cost_Date_Order_Item__c, 
                                    Schedule_Pick_Date__c, Schedule_Return_Date__c, Single_Handling_Fee_legacy__c, Submitter_Order_Item__c, Submitter_Order_Item_Legacy__c,
                                    Total_Retail_Cost_Legacy__c, Type__c FROM OrderItem WHERE OrderId = :originalOrderId]) {
                                        OrderItem clonedItem = ordItem.clone(false,false,false,false);
                                        clonedItem.OrderId = clonedOrder.Id;
                                        clonedItem.Actual_Return_Date__c = Null;
                                        clonedItem.Schedule_Pick_Date__c = pickUpDate;
                                        clonedItem.Requested_Borrowing_Period__c = borrowingPeriod;
                                        clonedItem.Schedule_Return_Date__c = clonedItem.Schedule_Pick_Date__c.addDays(num*7);
                                        clonedItem.Status__c = 'Unconfirmed';
                                        clonedItem.ListPrice = ordItem.PricebookEntry.UnitPrice;
                                        clonedItem.UnitPrice = ordItem.PricebookEntry.UnitPrice;
                                        ordItemList.add(clonedItem);
                                    }
            If(!ordItemList.isEmpty()) {
                insert ordItemList;
            }
            List<Order_Zip_Code__c> ordZipList = new List<Order_Zip_Code__c>();
            for(Order_Zip_Code__c ordZip : [Select Name, Zip_Code__c FROM Order_Zip_Code__c WHERE Order__c = :originalOrderId]) {
                Order_Zip_Code__c clonedZip = ordZip.clone(false,false,false,false);
                clonedZip.Order__c = clonedOrder.Id;
                ordZipList.add(clonedZip);
            }
            If(!ordZipList.isEmpty()) {
                insert ordZipList;
            }
            LowestQuantityCalculateClasss.lowestQuantityOrder2(new List<Order>{clonedOrder});
            returnOrderId = clonedOrder.Id;
            return returnOrderId;
        } catch (Exception e) {
            returnOrderId = e.getMessage();
            throw new AuraHandledException(e.getMessage());
        }
    }
	@AuraEnabled
    public static Account getBusinessHours(String orderId) {
        try {
            String affiliateId = [Select Id, Affiliate__c FROM Order where Id = :orderId LIMIT 1].Affiliate__c;
            return [ SELECT Id,Friday_End_Time__c,Friday_Start_Time__c, 
                    Monday_End_Time__c,Monday_Start_Time__c,
                    Saturday_End_Time__c,Saturday_Start_Time__c,
                    Sunday_End_Time__c,Sunday_Start_Time__c,
                    Thursday_End_Time__c,Thursday_Start_Time__c,
                    Tuesday_End_Time__c,Tuesday_Start_Time__c,
                    Wednesday_End_Time__c,Wednesday_Start_Time__c
                    FROM Account WHERE Id =: affiliateId ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}