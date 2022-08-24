import { api, LightningElement } from 'lwc';
import createCommuinityUser from '@salesforce/apex/EnableContactAsCommunityUser.createCommuinityUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EnableContactasCustomerUser extends LightningElement {

    @api
    recordId;

    connectedCallback() {
        console.log("Hi, I'm an action.",this.recordId);
        createCommuinityUser({recordId:this.recordId}).then(res =>{
            if(res){
                const evt = new ShowToastEvent({
                    title: "Enable Contact as user",
                    message: "User Enabled Success",
                    variant: "success",
                });
                this.dispatchEvent(evt);
            }
        }).catch(err =>{
            if(err){
                const evt = new ShowToastEvent({
                    title: "Enable Contact as user",
                    message: "User Enabled failed",
                    variant: "error",
                });
                this.dispatchEvent(evt);
            }
        })
      }
}