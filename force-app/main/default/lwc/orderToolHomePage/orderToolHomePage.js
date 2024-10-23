import { LightningElement,wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getFlag from '@salesforce/apex/PlaceOrderController.getFlag';
import getSignedDate from '@salesforce/apex/PlaceOrderController.getSignedDate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderToolHomePage extends NavigationMixin(LightningElement) {
    
    flag = false;
    contact;
    signed = false;
    showSign = false;
    isPrimary = false;
    @wire(getFlag) getaccFlag({data,error}){
        if(data){
            
            this.flag = data;
            console.log(this.flag);
            
        }
        else if(error){
            console.log(this.flag);
        }
    };

    @wire(getSignedDate) getAmSignedDate({data,error}){
        if(data){
            
            this.contact = data;
            console.log(this.contact);
            this.signed = (data.npsp__Primary_Affiliation__c === null || data.npsp__Primary_Affiliation__c === undefined) || (data.npsp__Primary_Affiliation__r.Agreement_Signed_Date__c != null && data.npsp__Primary_Affiliation__r.Agreement_Signed_Date__c != undefined);
            if( !this.signed){
                this.showSign = true;
                if((data.Primary_Contact__c || data.Executive_Contact__c))
                    this.isPrimary = true;
            }
        }
        else if(error){
            console.log(error);
        }
    };

    handleNavigate() {
        
       /*var compDefinition = {
            componentDef: "c:CreateOrderVfPage"
        };
       
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
*/      
        if(!this.flag){
                let currentURL  = window.location.href;
                currentURL = currentURL.replace("/s", "");
                window.open(currentURL+"CreateOrderVfPage", "_blank");
        } else{
            const evt = new ShowToastEvent({
                title: "Order Create",
                message: "The Account is Flagged, Please reach out to ToolBank",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
        /* this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                url: '/one/one.app#' + encodedCompDef
            }
        });

        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                componentName: "c__navigateToCreateOrderCmp"
            }
        });*/
    }

    signAgreement(){
            let currentURL  = window.location.href;
            currentURL = currentURL.replace("/s", "");
            window.open("https://toolbank.my.salesforce-sites.com/sign/ContactAgreementSignPage2?parentid="+ this.contact.Id, "_blank");
   
    }
    
}