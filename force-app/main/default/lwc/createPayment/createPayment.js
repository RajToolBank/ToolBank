import { api,wire, LightningElement } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import PAYMENT_OBJECT from '@salesforce/schema/Payments_TB__c';
import PAYMENT_METHOD from '@salesforce/schema/Payments_TB__c.Payment_Method__c';
import getOrderDetails from '@salesforce/apex/CreatePaymentController.getOrderDetails';
import refreshOrderDetails from '@salesforce/apex/CreatePaymentController.refreshOrderDetails';
import createPayment from '@salesforce/apex/CreatePaymentController.createPayment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreatePayment extends LightningElement {

    @api
    recordId;
    fieldsInfo;
    paymentMetadata;
    paymentMethods;
    method = "Credit Card";
    order;

    @wire(getObjectInfo, { objectApiName: PAYMENT_OBJECT })
    getorderMetadata(result){
        if(result.data){
            this.fieldsInfo = result.data.fields;
            this.paymentMetadata = result;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$paymentMetadata.data.defaultRecordTypeId',  fieldApiName: PAYMENT_METHOD }) 
    wireddesiredPickupTime({data, error}){
        if(data){
            this.paymentMethods  = data.values;
        }
        if(error){

        }
    };

    @wire(getOrderDetails,{recordId:'$recordId'}) 
    orderDetails({data,error}){
        if(data){
            console.log(data);
            this.order = data;
        }
    };

    makePaymentAndNew(event){
        let comments = this.template.querySelector(`[data-id="comments"]`);
        let amount = this.template.querySelector(`[data-id="amount"]`);
        let method = this.template.querySelector(`[data-id="method"]`);
        let payment = {
            comments:comments.value,
            amount:amount.value,
            method:method.value,
            orderId:this.order.Id
        }

        createPayment({payment: JSON.stringify(payment)})
        .then(res=>{
            comments.value = undefined;
            amount.value = undefined;
            method.value = undefined;
            const evt = new ShowToastEvent({
                title: "Make Payment",
                message: "Payment is successful.",
                variant: "success",
            });
            this.dispatchEvent(evt);
            return refreshOrderDetails({ recordId: this.recordId});
        }).then(res =>{
            this.order = res;
        }).catch(error=>{
            console.log(error);
            const evt = new ShowToastEvent({
                title: "Make Payment",
                message: error.body.pageErrors?error.body.pageErrors[0].message:error.body.message,
                variant: "error",
            });
            this.dispatchEvent(evt);
        })
    }

    makePayment(event){
        let comments = this.template.querySelector(`[data-id="comments"]`).value
        let amount = this.template.querySelector(`[data-id="amount"]`).value
        let method = this.template.querySelector(`[data-id="method"]`).value
        let payment = {
            comments:comments,
            amount:amount,
            method:method,
            orderId:this.order.Id
        }
        createPayment({payment: JSON.stringify(payment)})
        .then(res=>{
            const evt = new ShowToastEvent({
                title: "Make Payment",
                message: "Payment is successful.",
                variant: "success",
            });
            this.dispatchEvent(evt);
            location.reload();
        }).catch(error=>{
            console.log(error);
            const evt = new ShowToastEvent({
                title: "Make Payment",
                message: error.body.pageErrors?error.body.pageErrors[0].message:error.body.message,
                variant: "error",
            });
            this.dispatchEvent(evt);
        })
    }

    cancel(event){
        location.reload();
    }
}