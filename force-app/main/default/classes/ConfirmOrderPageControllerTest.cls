@isTest
public class ConfirmOrderPageControllerTest {
    
    @isTest
    private static void uniteTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        
        contact con = TestDataFactory.createContact(acc.Id);
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        acc.parentId = affiliate.Id;
        update acc;
        affiliate.Affiliate_Handling_Fee__c = 3;
        update affiliate;
        List<Asset> asset = [Select Id FROM Asset];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
            
        }
        update asset;
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset[0].id);
        
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset[0].id);

        List<orderItem> ordItemList = new List<orderItem>{ordItem};

        String ordItemJson= JSON.serialize(ordItemList);

        ConfirmOrderPageController.getOrderDetails(ord.Id);
        ConfirmOrderPageController.getTools(new list<string>{tool.id}, affiliate.id, null,null);
        ConfirmOrderPageController.getTools(new list<string>{tool.id}, affiliate.id, 'te',null);
        ConfirmOrderPageController.getTools(new list<string>{tool.id}, affiliate.id, 'te','null');
        ConfirmOrderPageController.getTools(new list<string>{tool.id}, affiliate.id, null,'null');




        ConfirmOrderPageController.singleItemLowestQuantity((String)ordItem.id,(String)tool.id,Date.today(),Date.today().addDays(7),(String)affiliate.Id,(Integer)ordItem.reserved_quantity__c);
        orderitemClass orderitem = new orderitemClass();
        
        orderitem.id = ordItem.id;
        orderitem.retDate = String.valueOf(Date.today().addDays(10));
        orderitem.pickupDate = String.valueOf(Date.today().addDays(3));
        orderitem.product2Id = tool.id;
        orderitem.accId = affiliate.id;
                            
        String ordItemJson2= JSON.serialize(new List<orderitemClass>{orderitem});
        ConfirmOrderPageController.massDateChangeLowest(ordItemJson2);

        itemClass itemcls = new itemClass();
        
        itemcls.Id = ord.id;
        itemcls.retDate = String.valueOf(Date.today().addDays(10));
        itemcls.pickdate = String.valueOf(Date.today().addDays(3));
        itemcls.pbeId = toolpbe.id;
        itemcls.unitprice = '10';
        itemcls.assetid=asset[0].id;
        itemcls.quantity = '5';
        itemcls.affiliateFee = '3';
        itemcls.week = '1 week';
        itemcls.reserv='5';
        itemcls.status = 'confirmed';
        orderNitemClass orderNitemClass = new orderNitemClass();
        orderNitemClass.order = ord;
        orderNitemClass.orderItems = new list<itemClass>{itemcls};
        ConfirmOrderPageController.saveOrder(JSON.serialize(orderNitemClass),JSON.serialize(new List<String>{ordItem.id}));
    }


    public class orderitemClass{
        String id;
        String retDate;
        String pickupDate;
        String product2Id;
        String accId;
    }

    public class orderNitemClass{
        order order;
        List<itemClass> orderItems;
    }

    public class itemClass{
        String Id;
        String pbeId;
        String unitprice;
        String assetid;
        String quantity;
        String affiliateFee;
        String week;
        String reserv;
        String retDate;
        String pickdate;
        String status;
    }
}