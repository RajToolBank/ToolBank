public without sharing class CreateRenwalOrderController {
    
    Id accid; 

    public CreateRenwalOrderController(ApexPages.standardController sc){
        accid = sc.getId();
    }

    public pageReference createOrder(){

        Account acc = [SELECT Id,parentid,name,parent.Membership_Fees_Amount__c,Membership_Join_Date__c FROM Account WHERE Id=:accid];

        Order ord = new order();

        ord.Name = 'Membership Renewal-'+acc.name;
        ord.accountId = accid;
        ord.affiliate__c = acc.parentid;
        ord.pricebook2Id = label.pricebookId;
        ord.status = acc.parent.Membership_Fees_Amount__c!= Null && acc.parent.Membership_Fees_Amount__c != 0 ?'Unpaid ': 'Closed';
        ord.effectiveDate = Date.today();
        ByPassValidations.ordStatusValidation = true;
        insert ord;

        Orderitem item = new Orderitem();

        item.orderId = ord.id;
        item.type__c = 'Additional Charges';
        item.Category__c = 'Membership';
        if(!Test.isRunningTest()){
        item.pricebookEntryId = label.MembershipFeePBEId;
        } else{
            item.pricebookEntryId = [SELECT Id FROM Pricebookentry limit 1].Id;
        }
        item.unitprice = acc.parent.Membership_Fees_Amount__c != NUll?acc.parent.Membership_Fees_Amount__c:0;
        item.quantity = 1;

        insert item;

        if(item.unitprice != Null && item.unitprice != 0){
            return new pageReference('/'+ord.Id).setRedirect(true);
        }else{
            acc.Membership_Status__c = 'Active';
            acc.Membership_Join_Date__c = acc.Membership_Join_Date__c != Null?acc.Membership_Join_Date__c:system.today();
            acc.Last_Membership_Date__c = system.today();
            acc.Membership_End_Date__c = system.today().addYears(1);
            update acc;
            return new pageReference('/'+accid).setRedirect(true);
        }

    }
}