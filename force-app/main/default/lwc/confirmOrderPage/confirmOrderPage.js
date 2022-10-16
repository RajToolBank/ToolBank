import { LightningElement,api,wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
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


export default class ConfirmOrderPage extends NavigationMixin(LightningElement) {

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
    showConflict = false;
    lable;
    order;
    orderItems;
    allOrderItems;
    conflictedOrderItems;
    productIds=[];
    setReturnDate = false;
    extendDays;
    matchingDate;
    timeZone;
    filters =[
        {label:"All", value:"All"},
        {label:"Unconfirmed", value:"Unconfirmed"},
        {label:"Confirmed", value:"Confirmed"},
        {label:"Deleted", value:"Deleted"}
    ];

    @wire(getTimeZone)
    getTimeZone({data,error}){
        if(data){
            console.log(data);
            this.timeZone = data;
        }
    }
    @wire(orderDetails,{recordId: "$recordId"}) orderDetail({data,error}){
        if(data){
            this.loaded = false;
            this.order = data.order;
            this.readonlyFlag = data.readOnly;
            this.orderItems = data.orderItemList;
            this.allOrderItems = data.orderItemList;
            let totalTimeInSeconds = (data.order.Scheduled_Pickup_Time__c/1000);
            let result = new Date(null, null, null, null, null, totalTimeInSeconds);
            let tempTime = result.toTimeString().split(' ')[0].substring(0,5)
            tempTime = tempTime.split(':');
            if(data.order.Scheduled_Pickup_Time__c && tempTime){
                const hour = parseInt(tempTime[0]) >12 && parseInt(tempTime[0]) !== 0 && parseInt(tempTime[0]) !== 12 ?(parseInt(tempTime)-12):(parseInt(tempTime[0]) === 0?12:tempTime[0]);
                const hour12 =  parseInt(tempTime[0]) >=12?"PM":"AM";
                this.schPickTime = hour+':'+tempTime[1]+' '+hour12;
            }
            for(let i in this.orderItems ){
                this.productIds.push(this.orderItems[i].Product2Id);
            }
            console.log(this.orderItems);
        }
        if(error){
            console.log(error);
            alert(error);
        }
    };

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
        this.loaded = true;
        this.setReturnDate = false;
        let template = this;
        let tempOrder = JSON.parse(JSON.stringify(this.order));
        let schpickDate = this.template.querySelector(`[data-id="scheduleDate"]`);
        let schpickTime = this.template.querySelector(`[data-id="scheduleTime"]`);
        let myArray;
        let itemIds = [];
        if(schpickTime.value){
            myArray = schpickTime.value.split(":");
            console.log((myArray[0]));
            console.log((myArray[0]/12));
            console.log(Math.round(myArray[0]/12));
            const hour = parseInt(myArray[0]) >12 && parseInt(myArray[0]) !== 0 && parseInt(myArray[0]) !== 12 ?(parseInt(myArray)-12):(parseInt(myArray[0]) === 0?12:myArray[0]);
            const min = myArray[1];
            const hour12 =  myArray[0]>=12?"PM":"AM";
            this.template.querySelector(`[data-sch="schtime"]`).innerHTML = hour+":"+min+" "+hour12;
            
        }
        tempOrder.EffectiveDate = schpickDate.value;
        tempOrder.Scheduled_Pickup_Time__c = schpickTime.value;
        this.template.querySelector(`[data-sch="schdate"]`).value = schpickDate.value;
        this.order = tempOrder;

       let allselectrows = template.template.querySelectorAll(`[data-check="checkbox"]`);
       allselectrows.forEach(function(ele){

            if(ele.checked){
                const recid = ele.dataset.recid;
                
                //let retDate = template.template.querySelector(`[data-id="`+recid+`"]`);
                let retDate = template.template.querySelector(`[data-return="`+recid+`"]`);

                let schDate = new Date(retDate.value);
                
                if(template.matchingDate){
                    
                    let mDate = new Date(template.matchingDate);
                    if(mDate === schDate)
                        schDate.setDate(schDate.getDate() + template.extendDays);

                }
                else if(template.extendDays){
                    schDate.setDate(schDate.getDate() + template.extendDays);
                    
                } else{
                   let borrowing = retDate.dataset.week;
                    if(borrowing){
                        borrowing = borrowing.replace("weeks", "");
                        borrowing = borrowing.replace("week", "");
                    }
                    
                    let week = parseInt(borrowing);
                    const days = week*7;
                    schDate = new Date(schpickDate.value);
                    schDate.setDate(schDate.getDate() + days);
                }
                let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(schDate);
                let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(schDate);
                let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(schDate);
                retDate.value = `${ye}-${mo}-${da}`;
                let date_1 = new Date(schpickDate.value);
                let date_2 = new Date(retDate.value);
                let difference = date_2.getTime() - date_1.getTime();
                let TotalDays = Math.ceil(difference / (1000 * 3600 * 24));
                let week = Math.ceil(TotalDays/7);
                let weeks = template.template.querySelector(`[data-weeks="`+recid+`"]`);
                let affiliateFee = parseInt(retDate.dataset.affiliatefee);
                let unitprice = parseFloat(retDate.dataset.unitprice);
                weeks.innerHTML = week+" "+(week===1?"week":"weeks")
                const handleFeePerTool = (((parseInt(affiliateFee)*unitprice)/100)*week).toFixed(2);
                let feeperTool = template.template.querySelector(`[data-toolfee="`+recid+`"]`);
                feeperTool.value = handleFeePerTool;
                let totalFee = template.template.querySelector(`[data-totalfee="`+recid+`"]`);
                let confirmqty = template.template.querySelector(`[data-confirm="`+recid+`"]`);
                const qty = parseInt(confirmqty.value);
                totalFee.value =(handleFeePerTool*qty).toFixed(2);
                let item = {
                    id:recid,
                    retDate:retDate.value,
                    pickupDate:schpickDate.value,
                    product2Id:ele.dataset.prod2id,
                    accId:template.order.Affiliate__c
                }
                itemIds.push(item);
            }
        });

        massDateChangeLowest({orderItems:JSON.stringify(itemIds)}).then(res=>{
            console.log(res);
            for(let i in itemIds){
                console.log(itemIds[i]);
                let row = template.template.querySelector(`[data-lowest="`+itemIds[i].id+`"]`);
                const lowest = res[itemIds[i].id];
                console.log(lowest);
                row.innerHTML = lowest;
                this.loaded = false;
            }
        }).catch(error =>{
            console.log(error);
        });

    }


    handleFilter(event){

        const filter = event.target.value;
        let state = this.template;
        let getAllTools = state.querySelectorAll(`[data-id="dataid"]`);
        let button = state.querySelector(`[data-title="updateStatus"]`);
        let getAllDeletedTools = state.querySelectorAll(`[data-deleted="yes"]`);
        
        if(filter == "Confirmed"){
            button.style.display = "block";
            button.label = "Unconfirm";
        }
        else if(filter == "Unconfirmed"){
            button.style.display = "block";
            button.label = "Confirm";
        }
        else if(filter == "All")
            button.style.display = "none";

        

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
                    if(status != filter && filter != "All"){
                        ele.style.display="none";
                        checkbox.classList.remove("filtered");
                    }else{
                        //if(ele.dataset.deleted != "yes"){
                            ele.style.display="table-row";
                            if(filter != "All")
                            checkbox.classList.add("filtered");
                            else checkbox.classList.remove("filtered");
                       // }
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
        this.loaded = true;
        const button = event.target.label;
        let state = this.template;
        let getAllAddedTools = this.template.querySelectorAll(`[data-check="checkbox"]`);
        getAllAddedTools.forEach(function(ele){
            if(ele.checked){
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
        });
        this.loaded = false;
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
        singleItemQuantity({itemId:itemId, product2Id:product2Id, pickupDate:pickupDate, returnDate:returnDate,affilliateId:affilliateId}).then(res =>{
            console.log(res);
            let row = this.template.querySelector(`[data-lowest="`+itemId+`"]`);
            row.innerHTML = res;
            this.loaded = false;
        }).catch(error =>{
            console.log(error);
        });
    }


    onselecttool(event){
        this.loaded = true;
        let addTools=[];
        let addAllTools=[];
        let itemIds = [];
        let returnDate = new Date(this.order.EffectiveDate);
        let week = this.order.Requested_Borrowing_Period__c;
        if(week){
            week = week.replace("weeks","");
            week = week.replace("week","");
        }
        week = week?(parseInt(week)*7):1;
        console.log(returnDate);
        returnDate.setDate(returnDate.getDate() + week);
        let count =0;
        for(let i in event.detail.tools){
            const temp = event.detail.tools[i];
            addTools.push(temp);
            addAllTools.push(temp);
            console.log("in loop");
            console.log(returnDate);
            let item = {
                id:temp.Id,
                retDate:returnDate,
                pickupDate:this.order.EffectiveDate,
                product2Id:temp.Product2Id,
                accId:this.order.Affiliate__c
            }
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

        console.log("orderitem list");
        console.log(itemIds);
        if(itemIds.length >0){
            massDateChangeLowest({orderItems:JSON.stringify(itemIds)}).then(res=>{
                console.log(res);
                for(let i in itemIds){
                    let row = this.template.querySelector(`[data-lowest="`+itemIds[i].id+`"]`);
                    const lowest =  res[itemIds[i].id];
                    row.innerHTML = lowest;
                    let returnDateEle = this.template.querySelector(`[data-return="`+itemIds[i].id+`"]`);
                    let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(returnDate);
                    let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(returnDate);
                    let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(returnDate);
                    returnDateEle.value = `${ye}-${mo}-${da}`;
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
                }else if(confirmQty === 0 && ele.dataset.status === "Confirmed"){
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
                tempOrder.Schedule_Return_Date__c = scheduleReturnDates[0];
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

            });
        }else{
            alert("Please fix the Quantity issue.");
            
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
        let schedulePickTime = this.template.querySelector(`[data-sch="schtime"]`).innerHTML;
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
            }else if(confirmQty === 0 && ele.dataset.status === "Confirmed"){
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
                tempOrder.Schedule_Return_Date__c = scheduleReturnDates[0];
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
                    this.orderItems = data.orderItemList;
                    this.allOrderItems = data.orderItemList;
                    for(let i in this.orderItems ){
                        this.productIds.push(this.orderItems[i].Product2Id);
                    }

                }).catch(error=>{

            });
        

        }else{
            alert("Please correct the error");
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
                state.productIds =[];
                for(let i in state.orderItems ){
                    state.productIds.push(state.orderItems[i].Product2Id);
                }
                state.loaded = false;

            }).catch(error =>{
                    console.log(error);
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
            
            if(ele.dataset.status !== 'Confirmed')
                StatusError=true;
            
            if(confirmQty > lowqty){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else if(confirmQty === 0){
                confirm.style.borderColor = "red";
                qtyError = true;
            }else confirm.style.borderColor = "";

            let item = {
                Id:ele.dataset.rowid,
                status:"Fulfilled",
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
            tempOrder.Schedule_Return_Date__c = scheduleReturnDates[0];
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
            });
            

        }else{

            if(StatusError && qtyError){
                alert("All Tools are not Confirmed Yet and Also confirmed quantity error is not fixed");
            }else if(StatusError)
            alert("All Tools are not Confirmed Yet");
            else if(qtyError)
            alert("Please fix the confirmed quantity error");
            this.loaded = false;
        }
    }

}