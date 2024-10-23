import { LightningElement,api,wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import momentJs from '@salesforce/resourceUrl/momentJs';
import momentTimezoneJs from '@salesforce/resourceUrl/momentTimezoneJs';
import NUMBER_FIELD from '@salesforce/schema/Order.OrderNumber';
import NAME from '@salesforce/schema/Order.Name';
import ACCOUNT_FIELD from '@salesforce/schema/Order.AccountId';
import ORDER_DATE_FIELD from '@salesforce/schema/Order.CreatedDate';
import TOOL_PICKED_FIELD from '@salesforce/schema/Order.Tools_Picked_Up_By__c';
import DESIRE_PICKED_DATE_FIELD from '@salesforce/schema/Order.Desired_Pickup_Date__c';
import DESIRE_PICKED_TIME_FIELD from '@salesforce/schema/Order.Desired_Pickup_Time__c';
import SCH_PICKED_TIME_FIELD from '@salesforce/schema/Order.EffectiveDate';
import SCH_PICKED_DATE_FIELD from '@salesforce/schema/Order.Scheduled_Pickup_Time__c';
import orderDetails from '@salesforce/apex/ConfirmOrderPageController.getOrderDetails';
import singleItemQuantity from '@salesforce/apex/ConfirmOrderPageController.singleItemLowestQuantity';
import massDateChangeLowest from '@salesforce/apex/ConfirmOrderPageController.massDateChangeLowest';
import saveOrder from '@salesforce/apex/ConfirmOrderPageController.saveOrder';
import getOrderDetailsDirect from '@salesforce/apex/ConfirmOrderPageController.getOrderDetailsDirect';
import getTimeZone from '@salesforce/apex/ConfirmOrderPageController.getTimeZone';
import getConflictedItems from '@salesforce/apex/ConfirmOrderPageController.getConflictedItems';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class ConfirmOrderPage extends NavigationMixin(LightningElement) {

    timeZone = TIME_ZONE;

    @api recordId;

    numberField = NUMBER_FIELD;
    ordername = NAME;
    agency = ACCOUNT_FIELD;
    orderDate = ORDER_DATE_FIELD;
    toolPickedField = TOOL_PICKED_FIELD;
    desirePickDateField = DESIRE_PICKED_DATE_FIELD;
    desirePickTimeField = DESIRE_PICKED_TIME_FIELD;
    schPickDateField = SCH_PICKED_TIME_FIELD;
    schPickTimeField = SCH_PICKED_DATE_FIELD;
    
    schPickTime;
    loaded = true;
    readonlyFlag = false;
    readonlyFlagDelete = false;
    showConflict = false;
    lable;
    order;
    orderItems;
    allOrderItems;
    conflictedOrderItems;
    productIds=[];
    setReturnDate = false;
    isEditModalOpen = false;
    extendDays;
    matchingDate;
    //timeZone;

    enablefulfill = true;
    filters =[
        {label:"All", value:"All"},
        {label:"Unconfirmed - Available", value:"Unconfirmed - Available"},
        {label:"Unconfirmed - Quantity Review", value:"Unconfirmed - Quantity Review"},
        {label:"Unconfirmed", value:"Unconfirmed"},
        {label:"Confirmed", value:"Confirmed"},
        {label:"Deleted", value:"Deleted"}
    ];

    fulfillMessage = false;
    ordertools;
    orderItemCmp=false;

    itemReturnDateDict;
    orderPickupDate;
    orderPickupTime;
   

    connectedCallback(){
        loadScript(this, momentJs)
        .then(() =>{
                
                window.console.log('moment loaded.');
            
        return loadScript(this, momentTimezoneJs); 
        }).then(() =>{
        
                console.log('moment time zone loaded.');
            
        }).catch(error=>{
            console.log(error);
        });
    }

    @wire(orderDetails,{recordId: "$recordId"}) orderDetail({data,error}){
        if(data){
            this.loaded = false;
            this.order = data.order;
            this.readonlyFlag = data.readOnly;
            this.readonlyFlagDelete = data.readOnlyDelete;
            this.orderItems = data.orderItemList;
            this.allOrderItems = data.orderItemList;
            let totalTimeInSeconds = (data.order.Scheduled_Pickup_Time__c/1000);
            let result = new Date(null, null, null, null, null, totalTimeInSeconds);
            let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
            tempTime = tempTime.split(':');
            this.orderPickupDate = this.order.EffectiveDate;
            if(data.order.Scheduled_Pickup_Time__c && tempTime){
                const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                this.schPickTime = hour+':'+tempTime[1]+' '+hour12;
                this.orderPickupTime = this.schPickTime;
            }
                let tempDict = {};
                for(let i in this.orderItems ){
                    this.productIds.push(this.orderItems[i].Product2Id);
                    let oItemId = this.orderItems[i].Id;
                    let retDate = this.orderItems[i].Schedule_Return_Date__c;
                    tempDict[oItemId]=retDate;
                }
                this.itemReturnDateDict = tempDict;

            if((data.order.Status === "Confirmed" || data.order.Status === "Fulfilled" || data.order.Status === "Partially Confirmed")&& !data.readOnly){
                this.enablefulfill = false;
            }
            console.log(this.orderItems);
        }
        if(error){
            console.log(error);
            //alert(error);
            const evt = new ShowToastEvent({
                title: "Error",
                message: JSON.stringify(error),
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    };

    openEditModal() {
        this.isEditModalOpen = true;
    }
    closeEditModal() {
        this.isEditModalOpen = false;
    }

    OpenModal(event){
        let allselectrows = this.template.querySelectorAll(`[data-check="checkbox"]`);
        console.log(allselectrows);
        let isAnySelected = false;
        allselectrows.forEach(function(ele){

            if(ele.checked){
                isAnySelected = true
            }
        })
        if(!isAnySelected){
            const evt = new ShowToastEvent({
                title: "Mass Date Change",
                message: "Please select atleast one tool",
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.setReturnDate = false;
            return
        }else{
            if(!this.setReturnDate)
                this.setReturnDate = true;
            else this.setReturnDate = false;
        }
    }

    handleTyping(event){
        this.template.querySelector(`[data-id="scheduleTime"]`).value="";
    }

    openConflictModal(event){
        this.showConflict = true;
        const itemId = event.target.dataset.itemid;
        let retDate = this.template.querySelector(`[data-return="`+itemId+`"]`);
        const product2Id = retDate.dataset.product2id;
        let schretDate = new Date(retDate.value);
        let pickupDate = this.order.EffectiveDate;
        const affilliateId = this.order.Affiliate__c;
        getConflictedItems({itemId:itemId, affilliateId:affilliateId, product2Id:product2Id, pickupDate:pickupDate, returnDate:schretDate })
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

    handleModalRadio(event){
        
        if(event.target.dataset.id === "radio-62"){
            this.extendDays = null;
            this.matchingDate = null;
        }else if(event.target.dataset.id === "radio-63"){
            this.extendDays=  parseInt(this.template.querySelector(`[data-id="radio63"]`).value);
            this.matchingDate = null;
        }else if(event.target.dataset.id === "radio-64"){
            this.extendDays = parseInt(this.template.querySelector(`[data-id="radio64"]`).value);
            this.matchingDate = parseInt(this.template.querySelector(`[data-id="matchingDate"]`).value);
        }
        
        console.log(this.extendDays);
        console.log(this.matchingDate);

    }

    handleModalOk(event){
        
        let template = this;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let schreturnDate = this.template.querySelector(`[data-id="scheduleReturnDate"]`);
        let schreturnTime = this.template.querySelector(`[data-id="scheduleReturnTime"]`);
        let schpickDate = this.template.querySelector(`[data-sch="schdate"]`);
        console.log(schreturnDate.value);
        let itemIds = [];
        let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);

        let beyondWeek  = false;
        let date_1 = new Date(schpickDate.value);
        let date_2 = new Date(schreturnDate.value);
        let difference = date_2.getTime() - date_1.getTime();
        let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
        let week = Math.ceil(TotalDays/7);
        date_1 = window.moment(schpickDate.value);
        date_2 = window.moment(schreturnDate.value);

        var diff = window.moment.duration(date_2.diff(date_1));
        week = Math.floor(diff.asWeeks())+ (diff.days()%7 >0?1:0);

        if(week > 16){
            beyondWeek = true;
        }

        if(!beyondWeek){
           // this.loaded = true;
            //this.setReturnDate = false;
            allselectrows.forEach(function(ele){

                if(ele.checked){
                    const recid = ele.dataset.recid;
                    
                    //let retDate = template.template.querySelector(`[data-id="`+recid+`"]`);
                    let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);

                    
                    retDate.value = schreturnDate.value;
                    
                    let weeks = template.template.querySelector(`[data-weeks="`+recid+`"]`);
                    let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                    let unitprice = parseFloat(retDate.dataset.unitprice);
                    weeks.innerHTML = week+" "+(week===1?"week":"weeks");
                    retDate.dataset.week = week+" "+(week===1?"week":"weeks");
                    const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                    let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                    feeperTool.value = handleFeePerTool;
                    let totalFee = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                    let confirmqty = template.template.querySelector(`[data-confirm="`+recid+`"]`);
                    let reqqty = template.template.querySelector(`[data-req="`+recid+`"]`);
                    let status =  template.template.querySelector(`[data-state="`+recid+`"]`);
                    
                    console.log("confirmqty ",confirmqty);
                    const cqty = parseInt(confirmqty.value);
                    const rqty = parseInt(reqqty.innerHTML);
                    console.log("qty ",cqty);
                    totalFee.value =(handleFeePerTool*cqty).toFixed(2);
                    let item = {
                        id:recid,
                        retDate:retDate.value,
                        pickupDate:schpickDate.value,
                        product2Id:ele.dataset.prod2id,
                        accId:template.order.Affiliate__c,
                        confirmqty:cqty,
                        reqQty:rqty,
                        status:status.innerHTML
                    }
                    itemIds.push(item);
                }
            });

            if(itemIds){
                this.ordertools = itemIds
                this.orderItemCmp = true;
                console.log("orderitems ",this.ordertools);
            }
        }else{
            const evt = new ShowToastEvent({
                title: "Confirm/Fulfill",
                message: "Please select a Return Date within 16 weeks of the Actual Pick Up Date.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }

    }

    orderItemListCmp(event){
        let evt = event.detail;
        let template = this;
        let itemIds = [];
        if(evt.status === "confirm"){
            let schreturnDate = this.template.querySelector(`[data-id="scheduleReturnDate"]`);
            this.orderItemCmp = false;
            if(schreturnDate){
                
                let tempOrder = JSON.parse(JSON.stringify(this.order));
                
                let schreturnTime = this.template.querySelector(`[data-id="scheduleReturnTime"]`);
                let schpickDate = this.template.querySelector(`[data-sch="schdate"]`);
                console.log(schreturnDate.value);
                
                let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);

                let beyondWeek  = false;
                let date_1 = new Date(schpickDate.value);
                let date_2 = new Date(schreturnDate.value);
                let difference = date_2.getTime() - date_1.getTime();
                let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
                let week = Math.ceil(TotalDays/7);

                date_1 = window.moment(schpickDate.value);
                date_2 = window.moment(schreturnDate.value);
        
                var diff = window.moment.duration(date_2.diff(date_1));
                week = Math.floor(diff.asWeeks())+ (diff.days()%7 >0?1:0);
                
                if(week > 16){
                    beyondWeek = true;
                }

                if(!beyondWeek){
                    this.loaded = true;
                    this.setReturnDate = false;
                    allselectrows.forEach(function(ele){

                        if(ele.checked){
                            const recid = ele.dataset.recid;
                            
                            //let retDate = template.template.querySelector(`[data-id="`+recid+`"]`);
                            let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);

                            
                            retDate.value = schreturnDate.value;
                            
                            let weeks = template.template.querySelector(`[data-weeks="`+recid+`"]`);
                            let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                            let unitprice = parseFloat(retDate.dataset.unitprice);
                            weeks.innerHTML = week+" "+(week===1?"week":"weeks");
                            retDate.dataset.week = week+" "+(week===1?"week":"weeks");
                            const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                            let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                            feeperTool.value = handleFeePerTool;
                            let totalFee = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                            let confirmqty = template.template.querySelector(`[data-confirm="`+recid+`"]`);
                            let reqqty = template.template.querySelector(`[data-req="`+recid+`"]`);
                            let status =  template.template.querySelector(`[data-state="`+recid+`"]`);
                            const qty = parseInt(confirmqty.value);
                            const rqty = parseInt(reqqty.innerHTML);
                            totalFee.value =(handleFeePerTool*qty).toFixed(2);
                            let item = {
                                id:recid,
                                retDate:retDate.value,
                                pickupDate:schpickDate.value,
                                product2Id:ele.dataset.prod2id,
                                accId:template.order.Affiliate__c,
                                confirmqty:qty,
                                reqQty:rqty,
                                status:status.innerHTML
                            }
                            itemIds.push(item);
                        }
                    });

                    if(itemIds){
                        this.ordertools = itemIds
                        this.orderItemCmp = true;
                        console.log("orderitems ",this.ordertools);
                    }
                    massDateChangeLowest({orderItems:JSON.stringify(itemIds)}).then(res=>{
                        console.log(res);
                        for(let i in itemIds){
                            console.log(itemIds[i]);
                            let row = template.template.querySelector(`[data-lowest="`+itemIds[i].id+`"]`);
                            let confirm = template.template.querySelector(`[data-confirm="`+itemIds[i].id+`"]`);
                            const lowest = res[itemIds[i].id];
                            console.log(lowest);
                            row.innerHTML = lowest;
                            if(lowest < confirm.value)
                                confirm.style.borderColor = "red";
                        }
                        this.loaded = false;
                        this.orderItemCmp = false;
                        const evt = new ShowToastEvent({
                            title: "Confirm/Fulfill",
                            message: "Date update success",
                            variant: "success", 
                        });
                        this.dispatchEvent(evt);
                    }).catch(error =>{
                        console.log(error);
                        const evt = new ShowToastEvent({
                            title: "Confirm/Fulfill",
                            message: error,
                            variant: "error",
                        });
                        this.dispatchEvent(evt);
                    });
                }else{
                    const evt = new ShowToastEvent({
                        title: "Confirm/Fulfill",
                        message: "Please select a Return Date within 16 weeks of the Actual Pick Up Date.",
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                }
            }else{
                //this.handlePickUpModalOk();
                let tempOrder = JSON.parse(JSON.stringify(this.order));
                let schpickDate = tempOrder.EffectiveDate
                let allselectrows = this.template.querySelectorAll(`[data-check="checkbox"]`);
                allselectrows.forEach(function(ele){

                    const recid = ele.dataset.recid;
                    
                    let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);

                    let schDate = new Date(retDate.value);
                  
                    let borrowing = retDate.dataset.week;
                    if(borrowing){
                        borrowing = borrowing.replace("weeks", "");
                        borrowing = borrowing.replace("week", "");
                    }
                        
                    let week = parseInt(borrowing);
                    const days = week*7;
                    schDate = new Date(schpickDate);
                    schDate = new Date(schDate.setHours(23,59,59,59))
                    console.log('Date before week : '+schDate);

                    //schDate.setDate(schDate.getDate() + (days+1));
                    schDate = window.moment(schpickDate, "YYYY-MM-DD").add(days,'days')
                    console.log('Date fter week : '+schDate);
                    console.log('Time Zone  : '+  template.timeZone);
                    //schDate= schDate.toLocaleString("en-US", {timeZone: template.timeZone});
                    //schDate = new Date(schDate);
                    console.log('Date Instance with Salesforce Locale timezone : '+schDate);
                // }
                    let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(schDate);
                    let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(schDate);
                    let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(schDate);
                    retDate.value = `${ye}-${mo}-${da}`;
                    let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                    let unitprice = parseFloat(retDate.dataset.unitprice);
                    const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                    let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                    feeperTool.value = handleFeePerTool;
                    let totalFee = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                    let confirmqty = template.template.querySelector(`[data-confirm="`+recid+`"]`);
                    let reqqty = template.template.querySelector(`[data-req="`+recid+`"]`);
                    let status =  template.template.querySelector(`[data-state="`+recid+`"]`);
                    const cqty = parseInt(confirmqty.value);
                    const rqty = parseInt(reqqty.innerHTML);
                    totalFee.value =(handleFeePerTool*cqty).toFixed(2);
                    let item = {
                        id:recid,
                        retDate:retDate.value,
                        pickupDate:schpickDate,
                        product2Id:ele.dataset.prod2id,
                        accId:template.order.Affiliate__c,
                        confirmqty:cqty,
                        reqQty:rqty,
                        status:status.innerHTML
                    }
                    itemIds.push(item);
                //}
            });
            console.log(itemIds);
            if(itemIds){
                this.ordertools = itemIds
                this.orderItemCmp = true;
                this.loaded = false;
                console.log("orderitems ",this.ordertools);
            }

                massDateChangeLowest({orderItems:JSON.stringify(itemIds)}).then(res=>{
                console.log(res);
                for(let i in itemIds){
                    console.log(itemIds[i]);
                    let row = template.template.querySelector(`[data-lowest="`+itemIds[i].id+`"]`);
                    let confirm = template.template.querySelector(`[data-confirm="`+itemIds[i].id+`"]`);
                    const lowest = res[itemIds[i].id];
                    console.log(lowest);
                    row.innerHTML = lowest;
                    this.loaded = false;
                    this.orderItemCmp = false;
                    if(lowest < confirm.value)
                        confirm.style.borderColor = "red";
                }
            }).catch(error =>{
                console.log(error);
            });
            }
        }else{
            this.orderItemCmp = false;
            let schdate = this.template.querySelector(`[data-sch="schdate"]`);
            let schTime = this.template.querySelector(`[data-sch="schtime"]`);
            console.log('this.order :: ', this.order);
            console.log('this.order.EffectiveDate :: ', this.order.EffectiveDate);
            schdate.value = this.orderPickupDate;
            let tempOrder = JSON.parse(JSON.stringify(this.order));
            tempOrder.EffectiveDate = this.orderPickupDate;
            this.order = tempOrder;
            this.schPickTime = this.orderPickupTime;
            schTime.value = this.orderPickupTime;

            let state = this.template;
            let getAllTools = state.querySelectorAll(`.filtered`);

            getAllTools.forEach(function(ele){
                    let recId = ele.dataset.recid;
                    let returnDateCmp = state.querySelector(`[data-return="`+recId+`"]`);
                    returnDateCmp.value = template.itemReturnDateDict[recId];
            });

        }
    }

    handlePickupDatePopUp(event){
        let pickDateModal = this.template.querySelector(`[data-id="PickDateConfirmModal"]`);
        if(pickDateModal.style.display === "none"){
            pickDateModal.style.display = "flex";
        }else{
            pickDateModal.style.display = "none";
        }

    }

    handlePickUpModalOk(event){
        this.loaded = true;
        let template = this;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let schpickDate = this.template.querySelector(`[data-id="scheduleDate"]`);
        let schepickTime = this.template.querySelector(`[data-id="scheduleTime"]`);
        let pickDateModal = this.template.querySelector(`[data-id="PickDateConfirmModal"]`);
        pickDateModal.style.display = "none";
        console.log("schpickDate ",this.isEditModalOpen);
        if(schpickDate.value && schepickTime.value){
            this.isEditModalOpen = false;
            let myArray;
            let itemIds = [];
            if(schepickTime.value){
                myArray = schepickTime.value.split(":");
                console.log(myArray);
                console.log((myArray[0]));
                console.log((myArray[0]/12));
                console.log(Math.round(myArray[0]/12));
                const hour = parseInt(myArray[0]) >12 && parseInt(myArray[0]) !== 0 && parseInt(myArray[0]) !== 12 ?(parseInt(myArray)-12):(parseInt(myArray[0]) === 0?12:myArray[0]);
                const min = myArray[1].replace("AM","").replace("PM","").trim();
                const hour12 =  myArray[1].indexOf("M") <0 ? (myArray[0]>=12?"PM":"AM"):(myArray[1].indexOf("PM") >0?"PM":"AM");
                this.template.querySelector(`[data-sch="schtime"]`).innerHTML = hour+":"+min+" "+hour12;
                this.schPickTime = hour+":"+min+" "+hour12;

                
            }
            tempOrder.EffectiveDate = schpickDate.value;
            tempOrder.Scheduled_Pickup_Time__c = this.schPickTime;
            this.template.querySelector(`[data-sch="schdate"]`).value = schpickDate.value;
            this.order = tempOrder;

            let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
            allselectrows.forEach(function(ele){

                    const recid = ele.dataset.recid;
                    
                    let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);

                    let schDate = new Date(retDate.value);
                  
                    let borrowing = retDate.dataset.week;
                    if(borrowing){
                        borrowing = borrowing.replace("weeks", "");
                        borrowing = borrowing.replace("week", "");
                    }
                    console.log('Time Zone  : '+  template.timeZone);
                    let week = parseInt(borrowing);
                    const days = week*7;
                    schDate = new Date(schpickDate.value);
                    console.log('schDate  : '+  schDate);
                    //schDate = window.moment().tz(schDate, "America/New_York");
                    //schDate = new Date(schDate.setHours(23,59,59,59))
                    console.log('Date before week : '+schpickDate.value);

                    //schDate.setDate(schDate.getDate() + (days+1));
                    schDate = window.moment(schpickDate.value, "YYYY-MM-DD").add(days,'days');
                    console.log('Date after week : '+schDate);
                   
                    //schDate= schDate.toLocaleString("en-US", {timeZone: template.timeZone});
                    //schDate = new Date(schDate);
                    console.log('Date Instance with Salesforce Locale timezone : '+schDate);
                // }
                    let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(schDate);
                    let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(schDate);
                    let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(schDate);
                    retDate.value = `${ye}-${mo}-${da}`;
                    let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                    let unitprice = parseFloat(retDate.dataset.unitprice);
                    const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                    let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                    feeperTool.value = handleFeePerTool;
                    let totalFee = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                    let confirmqty = template.template.querySelector(`[data-confirm="`+recid+`"]`);
                    let reqqty = template.template.querySelector(`[data-req="`+recid+`"]`);
                    let status =  template.template.querySelector(`[data-state="`+recid+`"]`);
                    const cqty = parseInt(confirmqty.value);
                    const rqty = parseInt(reqqty.innerHTML);
                    totalFee.value =(handleFeePerTool*cqty).toFixed(2);
                    let item = {
                        id:recid,
                        retDate:retDate.value,
                        pickupDate:schpickDate.value,
                        product2Id:ele.dataset.prod2id,
                        accId:template.order.Affiliate__c,
                        confirmqty:cqty,
                        reqQty:rqty,
                        status:status.innerHTML
                    }
                    itemIds.push(item);
                //}
            });
            console.log(itemIds);
            if(itemIds){
                this.ordertools = itemIds
                this.orderItemCmp = true;
                this.loaded = false;
                console.log("orderitems ",this.ordertools);
            }
           
        }else {
            this.loaded = false;
            const evt = new ShowToastEvent({
                title: "Schedule Date & Time",
                message: "Schedule pick date and time are mandatory.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }

    }

    handleFilter(event){

        const filter = event.target.value;
        let state = this.template;
        let getAllTools = state.querySelectorAll(`[data-id="dataid"]`);
        let button = state.querySelector(`[data-title="updateStatus"]`);
        let getAllDeletedTools = state.querySelectorAll(`[data-deleted="yes"]`);
        
        if(filter == "Confirmed"){
            button.disabled = false;
            button.label = "Unconfirm";
        }
        else if(filter == "Unconfirmed" || filter == "Unconfirmed - Available" || filter == "Unconfirmed - Quantity Review"){
            button.disabled = false;
            button.label = "Confirm";
        }
        else if(filter == "All")
            button.disabled = true;

        let selectall = state.querySelector(`[data-selectall="selectall"]`);
        selectall.checked = false;
        let getAllToolsSelected = state.querySelectorAll(`.filtered`);

        getAllToolsSelected.forEach(function(ele){
                ele.checked = false;
                ele.classList.remove("selected");
        });

            getAllTools.forEach(function(ele){
                if(filter == "Deleted" ){
                    if(ele.dataset.deleted == "yes"){
                        ele.style.display="table-row";
                    }else{
                        ele.style.display="none";
                    }
                }else if(ele.dataset.deleted !== "yes"){
                    const status = ele.dataset.status;
                    const checkbox = state.querySelector(`[data-recid="`+ele.dataset.rowid+`"]`);
                    const lowestAvaialbe = state.querySelector(`[data-lowest="`+ele.dataset.rowid+`"]`).innerHTML;
                    const requested = state.querySelector(`[data-req="`+ele.dataset.rowid+`"]`).innerHTML;
                    //const confirmed = state.querySelector(`[data-confirm="`+ele.dataset.rowid+`"]`).value;
                    if(filter === 'Unconfirmed - Available' && status === "Unconfirmed" && parseInt(lowestAvaialbe) >= parseInt(requested)){
                    
                        ele.style.display="table-row";
                        checkbox.classList.add("filtered");
                    }else if(filter === 'Unconfirmed - Quantity Review' && (status === "Unconfirmed" || status === "Unavailable") && parseInt(lowestAvaialbe) <= parseInt(requested)){
                        ele.style.display="table-row";
                        checkbox.classList.add("filtered");
                    }else if(status === filter ){
                        
                            ele.style.display="table-row";
                            checkbox.classList.add("filtered");
                       
                    }else{
                        if(filter != "All"){
                            ele.style.display="none";
                            checkbox.classList.remove("filtered");
                        }
                        else {
                            ele.style.display="table-row";
                            checkbox.classList.add("filtered");
                        }
                    }
                }else if(ele.dataset.deleted == "yes"){
                    ele.style.display="none";
                }
                
            });
        
    }

    handleSelectAll(event){
        let state = this.template;
        let getAllTools = state.querySelectorAll(`.filtered`);

        getAllTools.forEach(function(ele){
                ele.checked = event.target.checked;
                if(event.target.checked)
                    ele.classList.add("selected");
                else
                ele.classList.remove("selected");
        });
    }

    handleConfirmButton(event){
        
        const button = event.target.label;
        let state = this.template;
        let isChecked = false;
        //let allConfirmed = false;
       
       let getAllAddedTools = state.querySelectorAll(`[data-check="checkbox"]`);
        getAllAddedTools.forEach(function(ele){
            if(ele.checked){
                isChecked = true;
                let getAllUnConfirmedTd = state.querySelectorAll(`[data-state="`+ele.dataset.recid+`"]`);
                let getAllUnConfirmedTr = state.querySelectorAll(`[data-rowid="`+ele.dataset.recid+`"]`);
                getAllUnConfirmedTd.forEach(function(elem){
                    if(button === "Confirm"){
                        elem.innerHTML = "Confirmed";
                    }else if(button === "Unconfirm"){
                        elem.innerHTML = "Unconfirmed";
                    }
                });
    
                getAllUnConfirmedTr.forEach(function(elem){
                    
                    if(button === "Confirm"){
                        elem.dataset.status = "Confirmed";
                    }else if(button === "Unconfirm"){
                        elem.dataset.status = "Unconfirmed";
                    }
                });
            }

            // let getUnConfirmedTr = state.querySelector(`[data-rowid="`+ele.dataset.recid+`"]`);
            // if(getUnConfirmedTr.dataset.status === "Confirmed")
            //     allConfirmed = true;
            // else allConfirmed = false;

        });

        // if(allConfirmed) 
        // {
        //     this.enablefulfill = false;
       // }

        if(!isChecked){
            const evt = new ShowToastEvent({
                title: "Confirm",
                message: "Please select at least one tool line.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    }

    handleSelectCheck(event){
        const checked = event.target.checked;
        if(checked)
            event.target.classList.add("selected");
        else{
            event.target.classList.remove("selected");
        }
    }

    handleSearchFilter(event){
        const searchString = event.target.value.toLowerCase();
        let filteredItems = [];
        if(searchString.length >=2){
            for(let i in this.allOrderItems){
                
                const name = this.allOrderItems[i].Product2.Name.toLowerCase();
                let note;
                let alter;
                if(this.allOrderItems[i].Product2.Tool_Note__c) 
                    note = this.allOrderItems[i].Product2.Tool_Note__c.toLowerCase();
                
                if(this.allOrderItems[i].Product2.ProductCode)
                    alter = this.allOrderItems[i].Product2.ProductCode.toLowerCase();

                if((name && name.indexOf(searchString)>=0) || (note && note.indexOf(searchString)>=0) || (alter && alter.indexOf(searchString)>=0)){
                    filteredItems.push(this.allOrderItems[i]);
                }
            }
            this.orderItems = filteredItems;
        }else{
            this.orderItems = this.allOrderItems;
        }

        

    }


    handleDelete(event){
        let state = this.template;
        let getAllselectedTools = state.querySelectorAll(`.selected`);

        getAllselectedTools.forEach(function(ele){
            let row = state.querySelector(`[data-rowid="`+ele.dataset.recid+`"]`);
            row.style.display = "none";
            row.dataset.deleted = "yes";
            ele.checked = false;
        });
    }

    handleDateChang(event){
        this.loaded = true;
        const itemId = event.target.dataset.return;
        const product2Id = event.target.dataset.product2id;
        const affiliateFee = event.target.dataset.affiliatefee;
        const unitprice = event.target.dataset.unitprice;
        const pickupDate = this.order.EffectiveDate;
        const returnDate = event.target.value;
        let date_1 = new Date(pickupDate);
        let date_2 = new Date(returnDate);
        let difference = date_2.getTime() - date_1.getTime();
        let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
        let week = Math.ceil(TotalDays/7);
        date_1 = window.moment(pickupDate);
        date_2 = window.moment(returnDate);

        var diff = window.moment.duration(date_2.diff(date_1));
        week = Math.floor(diff.asWeeks())+ (diff.days()%7 >0?1:0);

        if(week <= 16){
            let weeks = this.template.querySelector(`[data-weeks="`+itemId+`"]`);
            weeks.innerHTML = week+" "+(week===1?"week":"weeks");
            event.target.dataset.week = week+" "+(week===1?"week":"weeks");
            const handleFeePerTool = (((parseInt(affiliateFee)*parseFloat(unitprice))/100)*week).toFixed(2);
            //let feeperTool = this.template.querySelector(`[data-toolfee="`+itemId+`"]`);
            //feeperTool.value =handleFeePerTool;
            let totalFee = this.template.querySelector(`[data-totalfee="`+itemId+`"]`);
            let confirmqty = this.template.querySelector(`[data-confirm="`+itemId+`"]`);
            const qty = parseInt(confirmqty.value);
            totalFee.value =(handleFeePerTool*qty).toFixed(2);
            const affilliateId = this.order.Affiliate__c;
            singleItemQuantity({itemId:itemId, product2Id:product2Id, pickupDate:pickupDate, returnDate:returnDate,affilliateId:affilliateId,confirmQty:qty}).then(res =>{
                console.log(res);
                let row = this.template.querySelector(`[data-lowest="`+itemId+`"]`);
                row.innerHTML = res;
                this.loaded = false;
            }).catch(error =>{
                console.log(error);
            });
        }else{
            let weeks = this.template.querySelector(`[data-weeks="`+itemId+`"]`);
            let borrowing = weeks.innerHTML;
            this.loaded = false;
            
            if(borrowing){
                borrowing = borrowing.replace("weeks", "");
                borrowing = borrowing.replace("week", "");
            }
            
            let week = parseInt(borrowing);
            const days = week*7;
            console.log("date_1 :: "+date_1);
            //date_1.setDate(date_1.getDate() + (days)); 
            date_1 = window.moment(pickupDate, "YYYY-MM-DD").add(days,'days');
            console.log("date_1 :: "+date_1);
            let retDate = this.template.querySelector(`[data-return="`+itemId+`"]`);
            let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(date_1);
            let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(date_1);
            let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(date_1);
            retDate.value = `${ye}-${mo}-${da}`;
            const evt = new ShowToastEvent({
                title: "Confirm/Fulfill",
                message: "Please select a Return Date within 16 weeks of the Actual Pick Up Date.",
                variant: "error",
            });
            this.dispatchEvent(evt);
        }
    }


    onselecttool(event){
        this.loaded = true;
        let addTools=[];
        let addAllTools=[];
        let itemIds = [];
        /*let week = this.order.Requested_Borrowing_Period__c;
        if(week){
            week = week.replace("weeks","");
            week = week.replace("week","");
        }*/
        
        

        let fulfillButton = this.template.querySelector(`[data-id="fulfill"]`);
        console.log(fulfillButton);
        fulfillButton.disabled = true;
        this.enablefulfill = true;
        let count =0;
        let tempdict = JSON.parse(JSON.stringify(this.itemReturnDateDict));
        for(let i in event.detail.tools){
            const temp = event.detail.tools[i];
            addTools.push(temp);
            addAllTools.push(temp);
            tempdict[temp.Id] = temp.Schedule_Return_Date__c;
            let item = {
                id:temp.Id,
                retDate:temp.Schedule_Return_Date__c,
                pickupDate:this.order.EffectiveDate,
                product2Id:temp.Product2Id,
                accId:this.order.Affiliate__c
            }
            this.itemReturnDateDict = tempdict;
            itemIds.push(item);
            count++;
        }
        
        if(count >0){
            if(this.orderItems)
                addTools.push(...JSON.parse(JSON.stringify(this.orderItems)));
            if(this.allOrderItems)
                addAllTools.push(...JSON.parse(JSON.stringify(this.allOrderItems)));
            this.orderItems = addTools ;
            this.allOrderItems = addAllTools;
            event.detail.tools = [];
        }

        console.log(" itemIds :: ",itemIds);
      
        if(itemIds.length >0){
            massDateChangeLowest({orderItems:JSON.stringify(itemIds)}).then(res=>{
                for(let i in itemIds){
                    let row = this.template.querySelector(`[data-lowest="`+itemIds[i].id+`"]`);
                    const lowest =  res[itemIds[i].id];
                    row.innerHTML = lowest;
                    let returnDateEle = this.template.querySelector(`[data-return="`+itemIds[i].id+`"]`);
                    console.log('apex :: ',itemIds[i].retDate);
                    let redDate = window.moment(itemIds[i].retDate,'YYYY-MM-DD');
                    console.log(redDate);
                    let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(redDate);
                    let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(redDate);
                    let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(redDate);
                    returnDateEle.value = `${ye}/${mo}/${da}`;
                    console.log(returnDateEle.value);
                }
                this.loaded = false;
            }).catch(error =>{
                console.log(error);
            });
        }
        
    }

    onSaveHandle(event){
        this.loaded = true;
        let template = this;
        let rows = this.template.querySelectorAll(`[data-id="dataid"]`);
        let orderitemsDetails = [];
        let orderItemToDelete = [];
        let qtyError = false;
        let schedulePickTime = this.template.querySelector(`[data-sch="schtime"]`).innerHTML;
        let schedulePickDate = this.template.querySelector(`[data-sch="schdate"]`).value;
        console.log(schedulePickDate);
        console.log(schedulePickTime);
        if(!schedulePickDate ||  !schedulePickTime || schedulePickDate === 0 || schedulePickTime === 0){
            const evt = new ShowToastEvent({
                title: "Schedule Pickup Time",
                message: "Please select a pickup date and time.",
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.loaded = false;

            return;
        }
        let scheduleReturnDates = [];
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let toolpickby =  this.template.querySelector(`[data-id="toolpickby"]`);
        
        rows.forEach(function(ele){
            if(ele.dataset.deleted !== "yes"){
                let req = template.template.querySelector(`[data-req="`+ele.dataset.rowid+`"]`);
                let confirm = template.template.querySelector(`[data-confirm="`+ele.dataset.rowid+`"]`);
                let returnDate = template.template.querySelector(`[data-return="`+ele.dataset.rowid+`"]`);
                let lowest = template.template.querySelector(`[data-lowest="`+ele.dataset.rowid+`"]`);
                const lowqty = (lowest.innerHTML)?parseInt(lowest.innerHTML):0;
                const confirmQty = (confirm.value)?parseInt(confirm.value):0;

                if(confirmQty > lowqty){
                    confirm.style.borderColor = "red";
                    qtyError = true;
                }else if(confirmQty === 0 && ele.dataset.status === "Confirmed"  && lowqty !==0){
                    confirm.style.borderColor = "red";
                    qtyError = true;
                }else confirm.style.borderColor = "";


                let item = {
                    Id:ele.dataset.rowid,
                    status:ele.dataset.status,
                    orderid: tempOrder.Id,
                    quantity: req.innerHTML,
                    week:returnDate.dataset.week,
                    reserv:confirm.value,
                    affiliateFee:returnDate.dataset.affiliatefee,
                    retDate:returnDate.value,
                    pickdate:tempOrder.EffectiveDate,
                    pbeId:returnDate.dataset.pbeid,
                    unitprice:returnDate.dataset.unitprice,
                    assetid:returnDate.dataset.assetid  
                }
                scheduleReturnDates.push(returnDate.value)
                orderitemsDetails.push(item);
            }else{
                orderItemToDelete.push(ele.dataset.rowid);
            }
        });
        scheduleReturnDates.sort(function(a,b){
            return new Date(b) - new Date(a);
          });

          if(!qtyError){
            if(toolpickby && toolpickby.value)
                tempOrder.Tools_Picked_Up_By__c = toolpickby.value;
            if(scheduleReturnDates)
                tempOrder.EndDate = scheduleReturnDates[0];
                console.log("schedulePickTime");
                console.log(schedulePickTime);
        if(schedulePickTime)
            tempOrder.Scheduled_Pickup_Time__c = schedulePickTime;
            let orderDetailsCmp = {
                order: tempOrder,
                orderItems:orderitemsDetails
            }
            
            saveOrder({orderNitemsDetails:JSON.stringify(orderDetailsCmp), orderItemToDelete:JSON.stringify(orderItemToDelete) }).then(res=>{
                this.loaded = false;
                
                location.reload();
            }).catch(error=>{
                console.log(error);
                const evt = new ShowToastEvent({
                    title: "Confirm/Fulfill",
                    message: error.body.message,
                    variant: "error",
                });
                this.dispatchEvent(evt);
            });
        }else{
           // alert("Please fix the Quantity issue.");
            const evt = new ShowToastEvent({
                title: "Quantity",
                message: "Please fix the Quantity issue.",
                variant: "error",
            });
            this.dispatchEvent(evt);
            
            this.loaded = false;
        }
    }

    onQuickSaveHandle(event){
        this.loaded = true;
        let template = this;
        let rows = this.template.querySelectorAll(`[data-id="dataid"]`);
        let orderitemsDetails = [];
        let orderItemToDelete = [];
        let qtyError = false;
        let schedulePickDate = this.template.querySelector(`[data-sch="schdate"]`).value;
        let schedulePickTime = this.template.querySelector(`[data-sch="schtime"]`).innerHTML;
        console.log(schedulePickDate);
        console.log(schedulePickTime);
        if(!schedulePickDate ||  !schedulePickTime || schedulePickDate === 0 || schedulePickTime === 0){
            const evt = new ShowToastEvent({
                title: "Schedule Pickup Time",
                message: "Please select a pickup date and time.",
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.loaded = false;

            return;
        }
        let scheduleReturnDates = [];
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let toolpickby =  this.template.querySelector(`[data-id="toolpickby"]`);
        rows.forEach(function(ele){
            if(ele.dataset.deleted !== "yes"){
            let req = template.template.querySelector(`[data-req="`+ele.dataset.rowid+`"]`);
            let confirm = template.template.querySelector(`[data-confirm="`+ele.dataset.rowid+`"]`);
            let returnDate = template.template.querySelector(`[data-return="`+ele.dataset.rowid+`"]`);
            let lowest = template.template.querySelector(`[data-lowest="`+ele.dataset.rowid+`"]`);
            const lowqty = (lowest.innerHTML)?parseInt(lowest.innerHTML):0;
            const confirmQty = (confirm.value)?parseInt(confirm.value):0;
            console.log(returnDate.dataset);
            if(confirmQty > lowqty){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else if(confirmQty === 0 && ele.dataset.status === "Confirmed" && lowqty !==0){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else confirm.style.borderColor = "";
            let item = {
                Id:ele.dataset.rowid,
                status:ele.dataset.status,
                orderid: tempOrder.Id,
                quantity: req.innerHTML,
                week:returnDate.dataset.week,
                reserv:confirm.value,
                affiliateFee:returnDate.dataset.affiliatefee,
                retDate:returnDate.value,
                pickdate:tempOrder.EffectiveDate,
                pbeId:returnDate.dataset.pbeid,
                unitprice:returnDate.dataset.unitprice,
                assetid:returnDate.dataset.assetid
            }
            scheduleReturnDates.push(returnDate.value);
            orderitemsDetails.push(item);
            }else{
                orderItemToDelete.push(ele.dataset.rowid);
            }
        });

        scheduleReturnDates.sort(function(a,b){
            return new Date(b) - new Date(a);
          });

        if(toolpickby && toolpickby.value)
                tempOrder.Tools_Picked_Up_By__c = toolpickby.value;
        if(scheduleReturnDates)
                tempOrder.EndDate = scheduleReturnDates[0];
                console.log("schedulePickTime");
                console.log(schedulePickTime);
        if(schedulePickTime)
            tempOrder.Scheduled_Pickup_Time__c = schedulePickTime;

        let orderDetailsCmp = {
            order: tempOrder,
            orderItems:orderitemsDetails
        }
        
        if(!qtyError){
            saveOrder({orderNitemsDetails:JSON.stringify(orderDetailsCmp), orderItemToDelete:JSON.stringify(orderItemToDelete)}).then(res=>{
                console.log(res);
                //this.loaded = false;
                if(res)
                return getOrderDetailsDirect({recordId: this.recordId});
            }).then(data =>{
                this.loaded = false;
                    this.order = data.order;
                    this.readonlyFlag = data.readOnly;
                    this.readonlyFlagDelete = data.readOnlyDelete;
                    this.orderItems = data.orderItemList;
                    this.allOrderItems = data.orderItemList;
                    this.orderPickupDate = this.order.EffectiveDate;
                    this.orderPickupTime = schedulePickTime;
                    let tempDict = {};
                    for(let i in this.orderItems ){
                        this.productIds.push(this.orderItems[i].Product2Id);
                        tempDict[this.orderItems[i].Id]=this.orderItems[i].Schedule_Return_Date__c;
                    }
                    this.itemReturnDateDict = tempDict;

                    if((data.order.Status === "Confirmed" || data.order.Status === "Fulfilled" || data.order.Status === "Partially Confirmed")&& !data.readOnly){
                        this.enablefulfill = false;
                    }

                }).catch(error=>{
                    console.log(error);
                    const evt = new ShowToastEvent({
                        title: "Confirm/Fulfill",
                        message: error.body.message,
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
            });
        

        }else{
            //alert("Please correct the error");
            const evt = new ShowToastEvent({
                title: "Confirm Quantity",
                message: "Please fix the Quantity issue.",
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.loaded = false;
        }
    }

    handleUndo(event){
        this.loaded = true;
        this.order = null;
        this.orderItems = [];
        this.allOrderItems = [];
        let recid = this.recordId
        let state = this;

        getOrderDetailsDirect({recordId: recid}).then(res =>{
                
                state.order = res.order;
                state.orderItems = res.orderItemList;
                state.allOrderItems = res.orderItemList;
                let totalTimeInSeconds = (res.order.Scheduled_Pickup_Time__c/1000);
                let result = new Date(null, null, null, null, null, totalTimeInSeconds);
                let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
                tempTime = tempTime.split(':');
                this.orderPickupDate = this.order.EffectiveDate;
                if(res.order.Scheduled_Pickup_Time__c && tempTime){
                    const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                    const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                    state.schPickTime = hour+':'+tempTime[1]+' '+hour12;
                }
                state.productIds =[];

                let tempDict = {};
                for(let i in state.orderItems ){
                    state.productIds.push(state.orderItems[i].Product2Id);
                    tempDict[this.orderItems[i].Id] =this.orderItems[i].Schedule_Return_Date__c;
                }
                this.itemReturnDateDict = tempDict;
                state.loaded = false;

            }).catch(error =>{
                    console.log(error);
                    const evt = new ShowToastEvent({
                        title: "Confirm/Fulfill",
                        message: error.body.message,
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                });

    }

    handleCancel(event){

       
            location.reload();
          
    }

    handlepdf(event){

        let template = this;
      
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: "/apex/orderConfirmPdf?id="+template.order.Id,
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    handleConfirmQty(event){
        let recid = event.target.dataset.confirm;
        let req = this.template.querySelector(`[data-lowest="`+recid+`"]`);
        let schpickDate = this.order.EffectiveDate;
        let retDate = this.template.querySelector(`[data-return="`+recid+`"]`);
        const lowqty = parseInt(req.innerHTML);
        const confirmQty = parseInt(event.target.value);
        let templist = JSON.parse(JSON.stringify(this.orderItems));
        for(var i in templist){
            if(templist[i].Id === recid){
                templist[i].Reserved_Quantity__c = confirmQty;
                break;
            }
        }
        this.orderItems = templist;
        if(confirmQty > lowqty){
            event.target.style.borderColor = "red";
        }else{ 
            
            event.target.style.borderColor = "none";            
            let date_1 = new Date(schpickDate);
            let date_2 = new Date(retDate.value);
            let difference = date_2.getTime() - date_1.getTime();
            let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
            let week = Math.ceil(TotalDays/7);
            let weeks = this.template.querySelector(`[data-weeks="`+recid+`"]`);
            let affiliateFee = parseInt(retDate.dataset.affiliatefee);
            let unitprice = parseFloat(retDate.dataset.unitprice);
            weeks.innerHTML = week+" "+(week===1?"week":"weeks")
            const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
           // let feeperTool = this.template.querySelector(`[data-toolfee="`+recid+`"]`);
           // feeperTool.value = handleFeePerTool;
            let totalFee = this.template.querySelector(`[data-totalfee="`+recid+`"]`);
            
            totalFee.value =(handleFeePerTool*confirmQty).toFixed(2);
        }

    }

    handleFulfillPopUp(event){
        
        let fulfillModal = this.template.querySelector(`[data-id="fulfillModal"]`);
        if(fulfillModal.style.display === "none"){
            let tempOrder = JSON.parse(JSON.stringify(this.order));
            let todayDate = new Date();
            let schpickDate = new Date(tempOrder.EffectiveDate+" 23:59:50");
            
            let yeToday = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(todayDate);
            let moToday = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(todayDate);
            let daToday = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(todayDate);

            let yePickup = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(schpickDate);
            let moPickup = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(schpickDate);
            let daPickup = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(schpickDate);

            if(yeToday === yePickup && moToday === moPickup && daToday === daPickup){
                this.fulfillMessage = false;
            }else {
                this.fulfillMessage = true;
            }
           

            fulfillModal.style.display = "flex";
        }else {
            fulfillModal.style.display = "none";
        }
    }

    handleFulfil(event){
        this.loaded = true;
        let template = this;
        let rows = this.template.querySelectorAll(`[data-id="dataid"]`);
        let orderitemsDetails = [];
        let StatusError = false;
        let qtyError = false;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let toolpickby =  this.template.querySelector(`[data-id="toolpickby"]`);
        let schedulePickTime = this.template.querySelector(`[data-sch="schtime"]`).innerHTML;
        let scheduleReturnDates = [];
        rows.forEach(function(ele){
            let req = template.template.querySelector(`[data-req="`+ele.dataset.rowid+`"]`);
            let confirm = template.template.querySelector(`[data-confirm="`+ele.dataset.rowid+`"]`);
            let returnDate = template.template.querySelector(`[data-return="`+ele.dataset.rowid+`"]`);
            let lowest = template.template.querySelector(`[data-lowest="`+ele.dataset.rowid+`"]`);
            const lowqty = (lowest.innerHTML)?parseInt(lowest.innerHTML):0;
            const confirmQty = (confirm.value)?parseInt(confirm.value):0;
            let status = "Fulfilled";
            if(ele.dataset.status !== 'Confirmed' && ele.dataset.status !== 'Fulfilled' && ele.dataset.status !== 'Unavailable' && lowqty !==0 && confirmQty !==0)
                StatusError=true;
            
            if(lowqty ===0 && confirmQty ===0)
            status = "Unavailable";
            
            if(confirmQty > lowqty){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else if(confirmQty === 0  && lowqty !==0){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else confirm.style.borderColor = "";

            let item = {
                Id:ele.dataset.rowid,
                status:status,
                orderid: tempOrder.Id,
                quantity: req.innerHTML,
                week:returnDate.dataset.week,
                reserv:confirm.value,
                affiliateFee:returnDate.dataset.affiliatefee,
                retDate:returnDate.value,
                pickdate:tempOrder.EffectiveDate,
                pbeId:returnDate.dataset.pbeid,
                unitprice:returnDate.dataset.unitprice,
                assetid:returnDate.dataset.assetid
            }
            scheduleReturnDates.push(returnDate.value);
            orderitemsDetails.push(item);
        });

        scheduleReturnDates.sort(function(a,b){
            return new Date(b) - new Date(a);
          });

        if(toolpickby && toolpickby.value)
            tempOrder.Tools_Picked_Up_By__c = toolpickby.value;
        if(scheduleReturnDates)
            tempOrder.EndDate = scheduleReturnDates[0];
            console.log("schedulePickTime");
            console.log(schedulePickTime);
        if(schedulePickTime){
           
            tempOrder.Scheduled_Pickup_Time__c = schedulePickTime;
            console.log(tempOrder.Scheduled_Pickup_Time__c);
        }

        let orderDetailsCmp = {
            order: tempOrder,
            orderItems:orderitemsDetails
        }
        
        if(!StatusError && !qtyError){
            saveOrder({orderNitemsDetails:JSON.stringify(orderDetailsCmp)}).then(res=>{
                this.loaded = false;
                
                location.reload();
            }).catch(error=>{
                console.log(error);
                const evt = new ShowToastEvent({
                    title: "Confirm/Fulfill",
                    message: error.body.message,
                    variant: "error",
                });
                this.dispatchEvent(evt);
            });
            

        }else{

            if(StatusError && qtyError){
                //alert("All Tools are not Confirmed Yet and Also confirmed quantity error is not fixed");
                const evt = new ShowToastEvent({
                    title: "Status & Quantity",
                    message: "All Tools are not Confirmed Yet and Also confirmed quantity error is not fixed",
                    variant: "error",
                });
                this.dispatchEvent(evt);
            }else if(StatusError){
               // alert("All Tools are not Confirmed Yet");
                const evt = new ShowToastEvent({
                    title: "Status",
                    message: "All Tools are not Confirmed Yet",
                    variant: "error",
                });
                this.dispatchEvent(evt);
            }
            else if(qtyError){
                //alert("Please fix the confirmed quantity error");
                const evt = new ShowToastEvent({
                    title: "Quantity",
                    message: "Please fix the confirmed quantity error",
                    variant: "error",
                });
                this.dispatchEvent(evt);
            }
            this.loaded = false;
        }
    }

}