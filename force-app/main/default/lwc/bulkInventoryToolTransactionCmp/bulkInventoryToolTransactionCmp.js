import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordType from '@salesforce/apex/CreateTransaction.getRecordType'
import ACCOUNT_Name_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_Id_FIELD from '@salesforce/schema/Account.Id';
import createbulkTransaction from '@salesforce/apex/CreateTransaction.createBulkTransaction'

export default class BulkInventoryToolTransactionCmp extends LightningElement {
    @api tools;
    loaded;
    transferRecordTypeId;
    recordTypes;
    @api selectedRecordType;
    selectedRecordTypeName;
    isTransferType;
    isSubtype;
    isCoporationDonation;
    @api subType;
    @api donatingCompany="";
    accountName;
    accountId;
    transferToId;
    @api note="";
    @api recordId;
    recordTypeDic = {};

    connectedCallback() {
        console.log("recordId ",this.recordId);
        getRecordType({}).then(res =>{
          let rectype = [];
          for(let v in res){
            const donation = res[v].label === "Donation";
            const inventoryAudit = res[v].label === "Inventory Audit";
            const purchased = res[v].label === "Purchased";
            const transfer = res[v].label === "Transfer";
            if(donation || inventoryAudit || purchased || transfer){
              rectype.push(res[v]);
            }
          }
            this.recordTypes = rectype;
            if(this.selectedRecordType && this.subType){
              this.isSubtype = true;
              if(this.subType === "Corporate Donation"){
                this.isCoporationDonation=true;
              }

            }
        }).catch(err=>{
            console.log(err);
        })

      }

    @wire(getObjectInfo, {objectApiName:'Transaction__c'})
    getObjectData({data,error}){
      if(data){
        const recordTypeInfos = data.recordTypeInfos;
        for (const recordTypeId in recordTypeInfos) {
          if (recordTypeInfos.hasOwnProperty(recordTypeId)) {
            
              const recordTypeInfo = recordTypeInfos[recordTypeId];
              this.recordTypeDic[recordTypeId] = recordTypeInfo.name;
              if (recordTypeInfo.name === 'Transfer') {
                  this.transferRecordTypeId = recordTypeInfo.recordTypeId;
                  
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
        console.log("data ",data);
        this.accountName = data.fields.Name.value;
        this.accountId = data.fields.Id.value;
      }else{
        console.log(error);
      }
    }

    handleQuantity(event){
        event.target.value=event.target.value.replace(/[^0-9]/g,'');
        let recId = event.target.dataset.qty;
        let toolIst = JSON.parse(JSON.stringify(this.tools));
        for(let i in toolIst){
          if(toolIst[i].InventoryId === recId){
            toolIst[i].Quantity = event.target.value;
          }
        }

        this.tools = toolIst;
        
    }

    handlePrevious(event){
      let prodIds = [];
      for(let i in this.tools){
        prodIds.push(this.tools[i].Product2Id);
      }

      const selectEvent = new CustomEvent('previous', {
        detail: { 
          "prodIds":prodIds,
          "toolseleted":this.tools,
          "rectype":this.selectedRecordType,
          "subtype":this.subType,
          "donatingcompany":this.donatingCompany,
          "note":this.note
                }
        });
      this.dispatchEvent(selectEvent);
    }

    handleDelete(event){
      const id = event.target.dataset.deleteindex;
      let itemlist = JSON.parse(JSON.stringify(this.tools));
      for(let i in itemlist){
        if(itemlist[i].InventoryId === id){
          itemlist.splice(i,1);
        }
      }

      this.tools = itemlist;
    }

    handleCancel(event){
      
      location.reload();
    }

    selectRecordType(event){
        this.isSubtype = false;
        let thiss = this;
        this.selectedRecordType = event.target.value;
        console.log('record type :: ',event.target);
        this.selectedRecordTypeName = this.recordTypeDic[this.selectedRecordType];
        this.subType = undefined;
        this.donatingCompany ="";
        this.isCoporationDonation = false;
        setTimeout(function(){
            
            if(thiss.selectedRecordType === thiss.transferRecordTypeId){
                thiss.isTransferType = true;
                thiss.isSubtype = false;
            }else {
                thiss.isSubtype = true;
                thiss.isTransferType = false;
                thiss.transferToId = undefined;
            }
          }, 1000);

          return false;
        
      }

      handleLookup(event){
        this.transferToId =event.detail.data.recordId;
      }

      selectsubType(event){
        this.subType = event.detail.value;
        if(event.detail.value === "Corporate Donation"){
          this.isCoporationDonation = true;
        }else {
          this.isCoporationDonation = false;
        }

        return false;
      }

      enterDonatingCompany(event){
        this.donatingCompany = event.target.value
      }

      enterNotes(event){
        this.note = event.target.value
      }

    createTransactions(event){
      this.loaded = true;
        if(!this.selectedRecordType){
          this.loaded = false;
            const evt = new ShowToastEvent({
                title: "Transaction",
                message: 'Pleaes select the type',
                variant: "error",
              });
              this.dispatchEvent(evt);
              return;
        }
        else if(!this.subType && !this.isTransferType){
          this.loaded = false;
            const evt = new ShowToastEvent({
              title: "Transaction",
              message: 'Pleaes select the sub type',
              variant: "error",
            });
            this.dispatchEvent(evt);
            return;
          }else if(this.isTransferType && !this.transferToId){
            this.loaded = false;
            const evt = new ShowToastEvent({
              title: "Transaction",
              message: 'Pleaes select the transfer to',
              variant: "error",
            });
            this.dispatchEvent(evt);
            return;
          }else if(this.subType === "Corporate Donation" && !this.donatingCompany){
            this.loaded = false;
            const evt = new ShowToastEvent({
              title: "Transaction",
              message: 'Pleaes enter the Donating Company',
              variant: "error",
            });
            this.dispatchEvent(evt);
            return;
          }

        let inventoryList = JSON.parse(JSON.stringify(this.tools));
        let isQtyNull = false;
        for(let i in inventoryList){
            const id = inventoryList[i].InventoryId;
            const qty = this.template.querySelector(`[data-qty="`+id+`"]`);
            const note = this.template.querySelector(`[data-note="`+id+`"]`);
            inventoryList[i]["Quantity"] = qty.value;
            inventoryList[i]["Note"] = this.note;
            inventoryList[i]["DonationCompany"] = this.donatingCompany;
            if(this.selectedRecordTypeName === 'Out Of Service' || this.selectedRecordTypeName === 'Transfer' || this.subType === 'Decrease' || this.subType === 'Lost from Inventory' || this.selectedRecordTypeName === 'Retired'){
                if(parseInt(qty.value) > parseInt(inventoryList[i].OnshelfQty)){
                  this.loaded = false;
                    event.target.value = 0;
                    const evt = new ShowToastEvent({
                        title: "Transaction",
                        message: 'The Quantity entered exceeds the On Shelf Quantity for some tools',
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                    return;
                }
            }
            if(!qty.value){
                isQtyNull = true;
            }
            
            
        }
        if(isQtyNull){
          this.loaded = false;
            const evt = new ShowToastEvent({
                title: "Transaction",
                message: 'Please enter the quantity',
                variant: "error",
            });
            this.dispatchEvent(evt);
            return;
        }

        createbulkTransaction({toolList:JSON.stringify(inventoryList),recordTypeId:this.selectedRecordType,subType:this.subType,affiliateId:this.transferToId})
        .then(res => {
            console.log(res);
            const evt = new ShowToastEvent({
                title: "Transaction",
                message: 'Transaction Created successfully',
                variant: "success",
            });
            this.dispatchEvent(evt);
            location.reload();
        }).catch(err=>{
          this.loaded = false;
            console.log(err);
            const evt = new ShowToastEvent({
                title: "Transaction",
                message: err,
                variant: "error",
            });
            this.dispatchEvent(evt);
            
        })
      }

}