import { api,wire, LightningElement, track } from 'lwc';
import createTransaction from '@salesforce/apex/CreateTransaction.createTransaction'
import getRecordType from '@salesforce/apex/CreateTransaction.getRecordType'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_Name_FIELD from '@salesforce/schema/Asset.Account.Name';
import ACCOUNT_Id_FIELD from '@salesforce/schema/Asset.Account.Id';
//import { CloseActionScreenEvent } from 'lightni ng/actions';

export default class CreateTransactionCmp extends LightningElement {
    @api recordId;
    accountName;
    accountId;
    transferRecordTypeId;
    @wire(getObjectInfo, {objectApiName:'Transaction__c'})
    getObjectData({data,error}){
      if(data){
        const recordTypeInfos = data.recordTypeInfos;
        for (const recordTypeId in recordTypeInfos) {
          if (recordTypeInfos.hasOwnProperty(recordTypeId)) {
              const recordTypeInfo = recordTypeInfos[recordTypeId];
              if (recordTypeInfo.name === 'Transfer') {
                  this.transferRecordTypeId = recordTypeInfo.recordTypeId;
                  break;
              }
          }
      }
        
      }
      if(error){

      }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_Name_FIELD,ACCOUNT_Id_FIELD] })
    account({data,error}){
      if(data){
        //console.log(data);
        this.accountName = data.fields.Account.displayValue;
        this.accountId = data.fields.Account.value.id;
      }
    }

    recordTypes=[];
    @track
    selectedRecordType;
    isRecordType = true;
    isTransferType;
    subTypes=[];
    subType;
    transferToId;


    connectedCallback() {

        getRecordType({}).then(res =>{
            this.recordTypes = res;
        }).catch(err=>{
            console.log(err);
        })

      }

      handleLookup(event){
        this.transferToId =event.detail.data.recordId;
      }

      selectRecordType(event){
        this.selectedRecordType = event.target.value;
        if(this.selectedRecordType === this.transferRecordTypeId){
          this.isTransferType = true;
        }
      }
      saveAndNext(event){
        
        let recordType = this.template.querySelector(`[data-id="recordType"]`);
        if(!recordType.value){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Please select the record type',
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
        if(!this.subType && !this.isTransferType){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Please select the sub type',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }else if(this.isTransferType && !this.transferToId){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Please select the transfer to',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }else if(!qty.value){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Please add quantity',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }
        
        let note = this.template.querySelector(`[data-id="note"]`);

        if(!note.value){
          const evt = new ShowToastEvent({
            title: "Transaction",
            message: 'Please enter the note',
            variant: "error",
          });
          this.dispatchEvent(evt);
          return;
        }

        createTransaction({inventoryId:this.recordId,recordTypeId:this.selectedRecordType,subType:this.subType,qty:qty.value,note:note.value,affiliateId:this.transferToId})
        .then(res =>{
            const evt = new ShowToastEvent({
                title: "Transaction Created",
                message: res,
                variant: (res !=="Successfull"?"error":"success"),
            });
            this.dispatchEvent(evt);
            if(res ==="Successfull")
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