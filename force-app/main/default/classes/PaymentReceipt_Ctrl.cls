public class PaymentReceipt_Ctrl {
    public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public Decimal waiver {get;set;}
    public Decimal orgCredit {get;set;}
    public Decimal creditCard {get;set;}
    public Decimal totalpaid {get;set;}
    String orderId;

    public PaymentReceipt_Ctrl(Apexpages.StandardController sc){

        getData= Toolbank_Help_Page__mdt.getAll().values();
         orderId = sc.getId();
        waiver = 0.00;
        orgCredit = 0.00;
        creditCard = 0.00;
        totalpaid = 0.00;
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
            attach.Name = 'Payment_Receipt'+Date.today().format()+'.pdf';
            attach.IsPrivate = false;
            attach.ParentId = orderId;
            insert attach;
        
    }
}