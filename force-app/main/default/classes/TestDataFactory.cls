public class TestDataFactory {
    
    public static Account createAccount(String name, String recordTypeid){
        Account acc = new Account(Name=name,recordTypeid=recordTypeid);
        insert acc;
        
        return acc;
    }
    
    public static contact createContact(String accId){
        contact con = new Contact();
        con.firstName = 'test';
        con.lastName = 'test';
        con.email = 'test@test.com';
        con.accountId = accId;
        insert con;
        
        return con;
    }
    
    public static Product2 createProduct(String Type){
        Product2 prod = new Product2();
        prod.name='test';
        prod.IsActive = true;
        prod.Type__c = Type;
        
        insert prod;
        
        return prod;
    }
    
    
    
    public static PricebookEntry createPricebookEntry(String prodId){
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.product2Id = prodId;
        pbe.pricebook2Id = Test.getstandardPricebookId();
        pbe.unitPrice = 10;
        
        insert pbe;
        
        return pbe;
    }
    
    public static Order createOrder(String accId, String conId, string affiliate){
        Order ord = new Order();
        ord.accountId = accId;
        ord.name='test';
        ord.Affiliate__c = affiliate;
        ord.BillToContactId = conId;
        ord.Status='Unconfirmed';
        ord.pricebook2Id = Test.getstandardPricebookId();
        ord.effectiveDate = Date.today();
        ord.Schedule_return_date__c = Date.today().addDays(7);
        ord.Desired_pickup_date__c = Date.today();
        ord.EndDate = Date.today().addDays(7);
        ord.Requested_Borrowing_Period__c = '1 week';
        insert ord;
        
        return ord;
    }
    
    public static OrderItem createOrderItem(String orderId, String pbeId,String assetid){
        OrderItem ordItem = new OrderItem();
        ordItem.orderId = orderId;
        ordItem.PricebookEntryId =pbeId;
        ordItem.Inventory_Tool__c = assetid;
        ordItem.unitPrice = 10;
        ordItem.Affiliate_Handling_Fee__c = 3;
        ordItem.status__c = 'Unconfirmed';
        ordItem.Quantity = 5;
        ordItem.reserved_quantity__c = 5;
        ordItem.Schedule_Pick_Date__c = Date.today();
        ordItem.Schedule_return_date__c = Date.today().addDays(7);
        insert ordItem;
        LowestQuantityCalculateClasss.lowestQuantityOrder2(new List<order>{new order(Id=orderId)});
        return ordItem;
    }
    
    public static Credit__c createCredit(String accId, Date ExpiredDate){
        Credit__c credit = new Credit__c();
        credit.Expiration_Date__c = ExpiredDate;
        credit.Organization__c = accId;
        credit.Amount__c = 100;
        credit.isActive__c = true;
        insert credit;
        
        return credit;
    }
    
    public static Payments_TB__c createpayment(Order ord){
        Payments_TB__c payment = new Payments_TB__c();
        payment.order__c = ord.id;
        payment.Payment_Method__c = 'Organizational Credit';
        payment.Amount__c = 10;
        insert payment;
        return payment;
    }
    
    //@future
    public static User createCustomerUser(contact con, profile prof) {
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        //insert r;
        User user1 = new User(
            Username = 'test12345@test.com',
            ContactId = con.Id,
            ProfileId = prof.Id,
            Alias = 'test123',
            Email = 'test12345@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'test12345',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
            //UserRoleId = r.Id
        );
        insert user1;
        return user1;
    }
    
    public static Affiliate_Account__c createAffiliateAccount(Id accId) {
        Affiliate_Account__c affAcc = new Affiliate_Account__c(Affiliate__c = accId);
        insert affAcc;
        return affAcc;
    }
    public static Zip_Code__c createZipCode(String zip) {
        Zip_Code__c zipCode = new Zip_Code__c(Name = zip, Zip_Code__c = zip);
        insert zipCode;
        return zipCode;
    }
    public static Transaction__c createTransaction(Id assestId, Id recType, String subType) {
        Transaction__c tran = new Transaction__c(Inventory__c = assestId, Sub_Type__c = subType, Quantity__c = 5, RecordtypeId = recType);
        insert tran;
        return tran;
    }
}