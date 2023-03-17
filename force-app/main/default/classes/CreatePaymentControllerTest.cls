@isTest
public class CreatePaymentControllerTest {
   
    @isTest
    static void unitTest1(){
        Account acc = new Account();
        acc.name = 'Test';
        
        insert acc;
        
        order order = new order();
		order.accountid = acc.id;
        order.Name = 'Test';
        order.pricebook2Id = Test.getstandardPricebookId();
        order.EffectiveDate = Date.today(); 
        order.Status = 'Unconfirmed';
        insert order;
        product2 product = TestDataFactory.createProduct('Additional Charges');
        PricebookEntry PricebookEntry = TestDataFactory.createPricebookEntry(product.id);
        
        OrderItem ordItem = new OrderItem();
        ordItem.orderId = order.Id;
        ordItem.PricebookEntryId =PricebookEntry.Id;
        ordItem.unitPrice = 10;
        ordItem.Affiliate_Handling_Fee__c = 0.03;
        ordItem.status__c = 'Unconfirmed';
        ordItem.Quantity = 1;
        ordItem.Lost__c = 1;
        ordItem.Requested_Borrowing_Period__c = '1 week';
        insert ordItem;
        
        CreatePaymentController.getOrderDetails(order.Id);
        CreatePaymentController.refreshOrderDetails(order.Id);
        String payment = '{'
                           +'     "comments":"comments",'
                           +'     "amount":"1",'
                           +'     "method":"Credit Card",'
                           +'     "orderId":"'+order.Id
                           +'"}';
        CreatePaymentController.createPayment(payment);
        
    }
}