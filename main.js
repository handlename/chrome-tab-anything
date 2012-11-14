window.addEventListener("load", function() {
    var doc   = window.document;
    var input = doc.getElementById("input");
    var list  = doc.getElementById("list");
    var items = [];

    var STATE = {
        NORMAL:   1,
        HIDDEN:   2,
        SELECTED: 4
    };

    input.focus();

    chrome.tabs.getAllInWindow(function(tabs) {
        items = parseTabs(tabs);

        selectDefaultItem();

        updateList();

        input.addEventListener("keyup", onInput);
        input.addEventListener("keydown", onSelect);
    });

    /// handle list

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
        elem.setAttribute("tab-id", item.tab.id);

        if (item.state === STATE.SELECTED) {
            elem.setAttribute("class", "selected");
        }

        return elem;
    }

    function updateList() {
        clearList();

        if (! selectedItem()) {
            selectDefaultItem();
        }

        itemsByState(STATE.NORMAL|STATE.SELECTED).forEach(function(item) {
            list.appendChild(createListElement(item));
        });
    }

    /// handle keys

    function onInput(event) {
        if (isEnter(event)) {
            // タブを切り替え
        }

        filterItems();

        updateList();
    }

    function onSelect(event) {
        var direction = parseKeyDirection(event);
        moveSelection(direction);

        if (direction !== 0) {
            event.preventDefault();
        }

        updateList();
    }

    function isEnter(event) {
        // Ctrl+m
        // Ctrl+j
        // Enter
    }

    function parseKeyDirection(event) {
        if (event.ctrlKey && event.which === 78) {
            // Ctrl+n
            return 1;
        }
        else if (event.ctrlKey && event.which == 80) {
            // Ctrl+p
            return -1;
        }

        return 0;
    }

    /// item utility

    function itemsByState(state) {
        var result = [];

        items.forEach(function(item) {
            if (item.state & state) {
                result.push(item);
            }
        });

        return result;
    }

    function selectedItem() {
        var selected;

        for (var i = 0; i < items.length; ++i) {
            if (items[i].state === STATE.SELECTED) {
                selected = items[i];
                break;
            }
        }

        return selected;
    }

    function selectDefaultItem() {
        itemsByState(STATE.NORMAL).state = STATE.SELECTED;
    }

    function moveSelection(direction) {
        if (direction == 0) {
            return;
        }

        var selected = items[0];

        items.forEach(function(item) {
            if (item.state === STATE.SELECTED) {
                selected = item;
            }
        });

        var normalItems      = itemsByState(STATE.NORMAL|STATE.SELECTED);
        var newSelectedIndex = items.indexOf(selected) + direction;
        var newSelected      = normalItems[newSelectedIndex];

        if (! newSelected) {
            return;
        }

        selected.state    = STATE.NORMAL;
        newSelected.state = STATE.SELECTED;
    }

    function filterItems() {
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

            if (flag) {
                if (item.state === STATE.HIDDEN) {
                    item.state = STATE.NORMAL;
                }
            }
            else {
                item.state = STATE.HIDDEN;
            }
        });
    }
});
