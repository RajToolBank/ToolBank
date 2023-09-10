@isTest
public class CreateRenwalOrderControllerTest {
    
    @isTest
    public static void unitTest1(){
        
        account acc1 = new account();
        acc1.name= 'fjh';
        acc1.Membership_Fees_Amount__c =66;
        insert acc1;

        account acc = new account();
        acc.name= 'fjh';
        acc.parentId = acc1.id;
        insert acc;

        Product2 addCharges = TestDataFactory.createProduct('Additional Charges');
        PricebookEntry pbeAdd = TestDataFactory.createPricebookEntry(addCharges.Id);

        PageReference pageRef = Page.CreateRenewalOrder;
        Test.setCurrentPage(pageRef);
        // put the lead id as a parameter
        ApexPages.currentPage().getParameters().put('id',acc.id);

        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        CreateRenwalOrderController obj = new CreateRenwalOrderController(sc);
          obj.createOrder();
       
    }
    
    
    @isTest
    public static void unitTest2(){
        
        account acc1 = new account();
        acc1.name= 'fjh';
        //acc1.Membership_Fees_Amount__c =66;
        insert acc1;

        account acc = new account();
        acc.name= 'fjh';
        acc.parentId = acc1.id;
        insert acc;

        Product2 addCharges = TestDataFactory.createProduct('Additional Charges');
        PricebookEntry pbeAdd = TestDataFactory.createPricebookEntry(addCharges.Id);

        PageReference pageRef = Page.CreateRenewalOrder;
        Test.setCurrentPage(pageRef);
        // put the lead id as a parameter
        ApexPages.currentPage().getParameters().put('id',acc.id);

        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        CreateRenwalOrderController obj = new CreateRenwalOrderController(sc);
          obj.createOrder();
       
    }
}