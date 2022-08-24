import { LightningElement,wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getFlag from '@salesforce/apex/PlaceOrderController.getFlag';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderToolHomePage extends NavigationMixin(LightningElement) {
    
    flag = false;

    @wire(getFlag) getaccFlag({data,error}){
        if(data){
            
            this.flag = data;
            console.log(this.flag);
            
        }
        else if(error){
            console.log(this.flag);
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
}