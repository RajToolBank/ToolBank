import { LightningElement } from 'lwc';

export default class HomePageOrderToolSf extends LightningElement {
    

   

    handleNavigate() {
       var compDefinition = {
            componentDef: "c:createOrder"
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));

        window.open("/one/one.app#"+encodedCompDef, "_blank");

    }
}