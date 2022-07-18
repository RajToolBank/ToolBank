import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class OrderToolHomePage extends NavigationMixin(LightningElement) {
    

   

    handleNavigate() {
       var compDefinition = {
            componentDef: "c:CreateOrderVfPage"
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));

        window.open("/CreateOrderVfPage", "_blank");

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