import { LightningElement,wire } from 'lwc';
import accid from '@salesforce/apex/PlaceOrderController.accid';

export default class CreateOrder extends LightningElement {
    orderInfo;
    orderTools;
    totalRetailCostOrder;
    totalToolHandlingFees;
    affiliateId;
    loaded = true;
    
    connectedCallback(){
        this.loaded = false;          
    }

    @wire(accid) getaccid({data,error}){
        if(data){
            
            this.affiliateId = data;
            console.log(data);
        }
    };

    handleinfo = (event) => {
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
        let infoLi = this.template.querySelector(`[data-id="infoLi"]`);
        let selectLi = this.template.querySelector(`[data-id="selectLi"]`);
        let reviewLi = this.template.querySelector(`[data-id="reviewLi"]`);
        orderinfo.style.display="block";
        orderselect.style.display="none";
        reviewPage.style.display="none";
        infoLi.classList.add("slds-is-active");
        infoLi.classList.remove("slds-is-incomplete");
        infoLi.classList.add("slds-is-current");
        reviewLi.classList.add("slds-is-incomplete");
        reviewLi.classList.remove("slds-is-current");
        reviewLi.classList.remove("slds-is-active");
        selectLi.classList.add("slds-is-incomplete");
        selectLi.classList.remove("slds-is-current");
        selectLi.classList.remove("slds-is-active");
        this.loaded = false;
    }


    handleSelectTool(event){
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
        let infoLi = this.template.querySelector(`[data-id="infoLi"]`);
        let selectLi = this.template.querySelector(`[data-id="selectLi"]`);
        let reviewLi = this.template.querySelector(`[data-id="reviewLi"]`);
        orderselect.style.display="block";
        orderinfo.style.display="none";
        reviewPage.style.display="none";
        selectLi.classList.add("slds-is-active");
        selectLi.classList.remove("slds-is-incomplete");
        selectLi.classList.add("slds-is-current");
        infoLi.classList.add("slds-is-incomplete");
        infoLi.classList.remove("slds-is-current");
        infoLi.classList.remove("slds-is-active");
        reviewLi.classList.add("slds-is-incomplete");
        reviewLi.classList.remove("slds-is-current");
        reviewLi.classList.remove("slds-is-active");
        this.loaded = false;
    }

    handleReviewPage(event){
        this.loaded = true;
        
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
        let infoLi = this.template.querySelector(`[data-id="infoLi"]`);
        let selectLi = this.template.querySelector(`[data-id="selectLi"]`);
        let reviewLi = this.template.querySelector(`[data-id="reviewLi"]`);
        reviewPage.style.display="block";
        orderselect.style.display="none";
        orderinfo.style.display="none";
        reviewLi.classList.add("slds-is-active");
        reviewLi.classList.remove("slds-is-incomplete");
        reviewLi.classList.add("slds-is-current");
        infoLi.classList.add("slds-is-incomplete");
        infoLi.classList.remove("slds-is-current");
        infoLi.classList.remove("slds-is-active");
        selectLi.classList.add("slds-is-incomplete");
        selectLi.classList.remove("slds-is-current");
        selectLi.classList.remove("slds-is-active");
        this.loaded = false;
    }

    handleOrderInfo(event){
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
       
        orderinfo.style.display="none";
        orderselect.style.display="block";
        reviewPage.style.display="none";

        console.log(event.detail);
        
        this.orderInfo = event.detail
        this.loaded = false;
    }

    handleSelectedTool(event){
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
       
        orderinfo.style.display="none";
        orderselect.style.display="none";
        reviewPage.style.display="block";
        this.orderTools = event.detail.tools;
        this.totalRetailCostOrder =event.detail.totalRetailCostOrder;
        this.totalToolHandlingFees = event.detail.totalToolHandlingFees;

        this.loaded = false;
        
    }

    reviewPagePreEvent(event){
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
       
        orderinfo.style.display="none";
        orderselect.style.display="block";
        reviewPage.style.display="none";
        this.loaded = false;
    }

    selectToolPreEvent(event){
        this.loaded = true;
        let orderinfo = this.template.querySelector(`[data-id="orderinfo"]`);
        let orderselect = this.template.querySelector(`[data-id="orderselect"]`);
        let reviewPage = this.template.querySelector(`[data-id="reviewPage"]`);
       
        orderinfo.style.display="block";
        orderselect.style.display="none";
        reviewPage.style.display="none";
        this.loaded = false;
    }

    handleAffiliateSelect(event){
        this.loaded = true;
        this.affiliateId = event.detail.affiliateId
        this.loaded = false;
    }
    
}