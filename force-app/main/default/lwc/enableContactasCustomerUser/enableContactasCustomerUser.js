import { api, LightningElement } from 'lwc';
import createCommuinityUser from '@salesforce/apex/EnableContactAsCommunityUser.createCommuinityUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EnableContactasCustomerUser extends LightningElement {

    @api
    recordId;
    progress = 0;
    isProgressing = false;


    connectedCallback() {
        
            // start
            this.isProgressing = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? 0 : this.progress + 1;
            }, 200);

        createCommuinityUser({recordId:this.recordId}).then(res =>{
            if(res){
                this.progress = 100;
                if(res === "Success"){
                    const evt = new ShowToastEvent({
                        title: "Enable Contact as user",
                        message: "User Enabled Success",
                        variant: "success",
                    });
                    this.dispatchEvent(evt);
                }else{
                    const evt = new ShowToastEvent({
                        title: "Enable Contact as user",
                        message: res,
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                }
                if (this.isProgressing) {
                    // stop
                    this.isProgressing = false;
                    clearInterval(this._interval);
                }
            }
        }).catch(err =>{
            console.log(err);
            if(err){
                let errorMessage =err.body.message;
                if(err.body.message.indexOf('Duplicate Username') >=0){
                    errorMessage = 'A user has already been activated with this Email Address/Username. You can update the email address or contact your Admin for additional assistance.';
                }
                const evt = new ShowToastEvent({
                    title: "Enable Contact as user",
                    message: errorMessage,
                    variant: "error",
                });
                this.dispatchEvent(evt);
                if (this.isProgressing) {
                    // stop
                    this.isProgressing = false;
                    clearInterval(this._interval);
                }
            }
        })
      }
      
      disconnectedCallback() {
        clearInterval(this._interval);
    }
}