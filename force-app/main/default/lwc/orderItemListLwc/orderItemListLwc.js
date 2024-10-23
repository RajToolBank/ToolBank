import { LightningElement, api } from 'lwc';
import massDateChangeLowest from '@salesforce/apex/OrderItemListController.massDateChangeLowest';
import getConflictedItems from '@salesforce/apex/OrderItemListController.getConflictedItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderItemListLwc extends LightningElement {
 
    @api ordertools;
    orderItems;
    showConflict;
    affilliateId;
    pickupDate;
    conflictedOrderItems;

    connectedCallback(){
        console.log("orderitemcmp ",this.ordertools);
        massDateChangeLowest({orderItems:JSON.stringify(this.ordertools)}).then(res=>{
            
            this.orderItems = res;
            console.log("res :: ",res);
            console.log("this.orderItems :: ",this.orderItems);
            if(res.length === 0){
                console.log(res);
                const evt = new CustomEvent("datechangeconfirm",{
                    detail:{
                        status:"confirm"
                    }
                });
                this.dispatchEvent(evt);
            }else{
                this.affilliateId = res[0].Order.Affiliate__c;
                this.pickupDate = res[0].Schedule_Pick_Date__c;
            }
        }).catch(error =>{
            console.log(error);
        });
    }

    openConflictModal(event){
        this.showConflict = true;
        const prodid = event.target.dataset.prodid;
        const itemId = event.target.dataset.itemid;
        let retDate = this.template.querySelector(`[data-product2id="`+prodid+`"]`);
        const product2Id = retDate.dataset.product2id;
        let schretDate = new Date(retDate.value);
        let pickDate = this.pickupDate;
        console.log(pickDate);
        console.log(this.pickupDate);
        getConflictedItems({itemId:itemId, affilliateId:this.affilliateId, product2Id:product2Id, pickupDate:pickDate, returnDate:schretDate })
        .then(res=>{
            this.conflictedOrderItems = res;
            console.log(res);
        }).catch(error =>{
            console.log(error);
        })
    }

    closeConflictModal(event){
        this.conflictedOrderItems = false;
        this.showConflict = false;
    }
    
    handleNext(event){
        const evt = new CustomEvent("datechangeconfirm",{
            detail:{
                status:"confirm"
            }
        });
        this.dispatchEvent(evt);
    }

    handleCancel(event){
        const evt = new CustomEvent("datechangeconfirm",{
            detail:{
                status:"cancel"
            }
        });
        this.dispatchEvent(evt);
    }
}