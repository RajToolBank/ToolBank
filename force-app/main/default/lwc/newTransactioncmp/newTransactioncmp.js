import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class newTransactioncmp extends LightningElement {
    @api recordId; 
    @api recordName;
    @api inventoryid;
    @api inventoryName;

    qty;
    type;
    Note;  
   handleqtyChange(event){
       console.log(event.detail.value);
       this.qty = event.detail.value;

   }

   handletypeChange(event){
    console.log(event.detail.value);
    this.type = event.detail.value;
    }

    handlenoteChange(event){
        console.log(event.detail.value);
        this.Note = event.detail.value;
    }

    // Insert record.
    createTransaction(){
        // Creating mapping of fields of Account with values
        var fields = {'Inventory__c' : this.inventoryid, 'Order_Product__c' : this.recordId, 'Quantity__c' : this.qty, 'Type__c' : this.type, 'Note__c' : this.Note};
        // Record details to pass to create method with api name of Object.
        var objRecordInput = {'apiName' : 'Transaction__c', fields};
        // LDS method to create record.
        createRecord(objRecordInput).then(response => {
            alert('Transaction created with Id: ' +response.id);
        }).catch(error => {
            alert('Error: ' +JSON.stringify(error));
        });
    }
}