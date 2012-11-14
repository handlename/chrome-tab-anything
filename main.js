window.addEventListener("load", function() {
    var doc   = window.document;
    var input = doc.getElementById("input");
    var list  = doc.getElementById("list");
    var items  = [];

    var STATE = {
        NORMAL: 0,
        HIDDEN: 2
    };

    input.focus();

    chrome.tabs.getAllInWindow(function(tabs) {
        items = parseTabs(tabs);
        updateList();
        input.addEventListener("keyup", onInput);
    });

    function clearList() {
        list.innerHTML = "";
    }

    function parseTabs(tabs) {
        var items = [];

        tabs.forEach(function(tab) {
            items.push({
                state: STATE.NORMAL,
                tab:   tab
            });
        });

        return items;
    }

    function createListElement(item) {
        var elem = doc.createElement("li");
        elem.innerHTML = item.tab.title;
        return elem;
    }

    function updateList() {
        clearList();

        items.forEach(function(item) {
            if (item.state !== STATE.NORMAL) {
                return;
            }

            list.appendChild(createListElement(item));
        });
    }

    function onInput(event) {
        var patterns = input.value.split(/ +/).map(function(word) {
            return new RegExp(word, "i");
        });

        var flag;

        items.forEach(function(item) {
            flag = false;

            patterns.forEach(function(pattern) {
                if (item.tab.title.match(pattern)) {
                    flag = true;
                }
            });

            item.state = flag ? STATE.NORMAL : STATE.HIDDEN;
        });

        updateList();
    }
});
