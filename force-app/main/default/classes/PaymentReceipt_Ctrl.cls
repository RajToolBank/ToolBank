public class PaymentReceipt_Ctrl {
    public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public Decimal waiver {get;set;}
    public Decimal orgCredit {get;set;}
    public Decimal creditCard {get;set;}
    public Decimal totalpaid {get;set;}
    public Decimal totalOrderFees {get;set;}
    String orderId;
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        //Milliseconds to Day
        return  tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.00);
    }}

    public PaymentReceipt_Ctrl(Apexpages.StandardController sc){
        totalOrderFees = 0.00;
        getData= Toolbank_Help_Page__mdt.getAll().values();
        orderId = sc.getId();
        Order order = (Order)sc.getRecord();
        waiver = 0.00;
        orgCredit = 0.00;
        creditCard = 0.00;
        totalpaid = 0.00;
        totalOrderFees += order.Total_Handling_Fees__c != null?order.Total_Handling_Fees__c:0;
        totalOrderFees += order.Total_Late_Fee__c != null?order.Total_Late_Fee__c:0;
        totalOrderFees += order.Lost_R_Fee__c != null?order.Lost_R_Fee__c:0;
        totalOrderFees = totalOrderFees.setScale(2);
        for(Payments_TB__c payment: [SELECT Id, Payment_Method__c, Amount__c FROM Payments_TB__c WHERE Order__c =: orderId ]){
            if(payment.Payment_Method__c == 'Credit Card'){
                creditCard += payment.Amount__c;
            }else if(payment.Payment_Method__c == 'Organizational Credit'){
                orgCredit += payment.Amount__c;
            }else if(payment.Payment_Method__c == 'Waiver - External Sponsor' || payment.Payment_Method__c == 'Waiver - External Sponsor'){
                waiver += payment.Amount__c;
            }
            totalpaid += payment.Amount__c;
        }
    }

    public void updateOrder(){
       
            PageReference PDf =  Page.PaymentReceipt;//Replace attachmentPDf with the page you have rendered as PDF
            PDf.getParameters().put('Id',orderId);
            PDf.setRedirect(true);
            Attachment attach = new Attachment();
            Blob b ;
            b = PDf.getContentAsPDF();
            attach.Body = b;
            attach.Name = 'Payment_Receipt_'+Date.today().format()+'.pdf';
            attach.IsPrivate = false;
            attach.ParentId = orderId;
            insert attach;
        
    }
}