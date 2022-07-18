public class PaymentReceipt_Ctrl {
    public List<Toolbank_Help_Page__mdt> getData {get;set;}
    public PaymentReceipt_Ctrl(Apexpages.StandardController sc){
        getData= Toolbank_Help_Page__mdt.getAll().values();
    }

    public void updateOrder(){

    }
}