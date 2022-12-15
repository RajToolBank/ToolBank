import { api, LightningElement } from 'lwc';
import placeOrder from '@salesforce/apex/PlaceOrderController.placeOrder';


export default class ReviewPage extends LightningElement {


    @api orderDetails;
    @api orderTools;
    @api totalRetailCostOrder;
    @api totalToolHandlingFees;
    loaded = false;
    success = false;
    error = false;
    review = false;
    orderId;

    handlePrevious = (event) =>{
        
        const selectEvent = new CustomEvent('prereviewpage', {
            detail: "Review Page Previous Button"
            });
            this.dispatchEvent(selectEvent);
    } 

    createOrder(event){
        console.log(event.detail);
        console.log(event.target);
        event.target.disabled= true;
        event.target.style = "background-color:grey";
        this.loaded = true;
        const order ={
            order:this.orderDetails,
            tools:this.orderTools
        }
        let currentURL  = window.location.href;
        currentURL = currentURL.replace("/s", "");
        currentURL = currentURL.replace("/CreateOrderVfPage", "");
      
        
        placeOrder({Order: JSON.stringify(order)}).then(res =>{
            console.log(res);
            this.loaded = false;
            this.review = true;
            if(res !== '/null'){
                this.success = true;
                this.orderId = currentURL+res;
            }else{
                this.error = true;
            }
        }).catch(error =>{
            console.log(error);
            this.error = true;
            this.loaded = false;
            this.review = true;
        });
    }

}