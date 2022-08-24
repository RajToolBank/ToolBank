({
    myAction : function(component, event, helper) {
        setTimeout(function () {$A.get('e.force:closeQuickAction').fire();}, 1500);
    }
})