import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getRelatedListRecords from '@salesforce/apex/AdditionalChargesController.getOrderItems';

export default class OrderToolRelatedList  extends NavigationMixin(LightningElement) {
    @api  recordId;
    records;
    error;
    orderlink;
    num;

    @wire(getRelatedListRecords, {orderid: '$recordId' })
    orderItems({ error, data }) {
        if (data) {
            
            let itemlist = JSON.parse(JSON.stringify(data));
            for(let i in itemlist){
                itemlist[i].UnitPrice = itemlist[i].UnitPrice.toFixed(2);
                itemlist[i].Total_Handling_Fee__c = itemlist[i].Total_Handling_Fee__c.toFixed(2);
                itemlist[i].Tool_Handling_Fee_Per_Item__c = itemlist[i].Tool_Handling_Fee_Per_Item__c.toFixed(2);
            }
            this.records = itemlist;
            this.num = data.length; 
            this.error = undefined;
            this.orderlink = "/lightning/r/Order/"+this.recordId+"/related/OrderItems/view";
            
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
        
        
    }  
    
    viewRecord(event) {
        // Navigate to Account record page
        console.log(event.target.dataset.value);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": event.target.dataset.value,
                "objectApiName": "OrderItem",
                "actionName": "view",
                "target":"_blank"
            },
        });
    }
}