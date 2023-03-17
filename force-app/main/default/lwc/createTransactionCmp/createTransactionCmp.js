import { api, LightningElement, track } from 'lwc';
import createTransaction from '@salesforce/apex/CreateTransaction.createTransaction'
import getRecordType from '@salesforce/apex/CreateTransaction.getRecordType'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateTransactionCmp extends LightningElement {
    @api recordId;
   

    recordTypes=[];
    @track
    selectedRecordType;
    isRecordType = true;
    subTypes=[];
    subType;


    connectedCallback() {

        getRecordType({}).then(res =>{
            console.log(res);
            this.recordTypes = res;
        }).catch(err=>{
            console.log(err);
        })

      }

      selectRecordType(event){

        this.selectedRecordType = event.target.value;
      }
      saveAndNext(event){
        
        let recordType = this.template.querySelector(`[data-id="recordType"]`);
        if(!recordType.value){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Pleaes select the record type',
            variant: "error",
        });
        this.dispatchEvent(evt);
        }else{
          this.isRecordType = false
        }
        
      }

      selectsubType(event){
        this.subType = event.detail.value;
      }

      saveTransaction(event){
        let qty = this.template.querySelector(`[data-id="qty"]`);
        if(!this.subType){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Pleaes select the sub type',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }else if(!qty.value){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Pleaes add quantity',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }
        
        let note = this.template.querySelector(`[data-id="note"]`);
        createTransaction({inventoryId:this.recordId,recordTypeId:this.selectedRecordType,subType:this.subType,qty:qty.value,note:note.value})
        .then(res =>{
            const evt = new ShowToastEvent({
                title: "Transaction Created",
                message: res,
                variant: "success",
            });
            this.dispatchEvent(evt);
            location.reload();
        }).catch(err =>{
          console.log(err);
            const evt = new ShowToastEvent({
                title: "Transaction Error",
                message: err.body.pageErrors[0].message,
                variant: "error",
            });
            this.dispatchEvent(evt);
        })


      }
}