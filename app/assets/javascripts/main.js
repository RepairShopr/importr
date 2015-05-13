$(document).ready(function() {
    /** drop target **/
    var _target = document.getElementById('drop_zone');

    /** Spinner **/
    var spinner;

    var _workstart = function() { spinner = new Spinner().spin(_target); }
    var _workend = function() {
        spinner.stop();
    }

    /** Alerts **/
    var _badfile = function() {
        alertify.alert('This file does not appear to be a valid Excel file.  If we made a mistake, please send this file to <a href="mailto:dev@sheetjs.com?subject=I+broke+your+stuff">dev@sheetjs.com</a> so we can take a look.', function(){});
    };

    var _pending = function() {
        alertify.alert('Please wait until the current file is processed.', function(){});
    };

    var _large = function(len, cb) {
        alertify.confirm("This file is " + len + " bytes and may take a few moments.  Your browser may lock up during this process.  Shall we play?", cb);
    };

    var _failed = function(e) {
        console.log(e, e.stack);
        alertify.alert('We unfortunately dropped the ball here.  We noticed some issues with the grid recently, so please test the file using the direct parsers for <a href="/js-xls/">XLS</a> and <a href="/js-xlsx/">XLSX</a> files.  If there are issues with the direct parsers, please send this file to <a href="mailto:dev@sheetjs.com?subject=I+broke+your+stuff">dev@sheetjs.com</a> so we can make things right.', function(){});
    };

    /** Handsontable magic **/
    var boldRenderer = function (instance, td, row, col, prop, value, cellProperties) {
        Handsontable.TextCell.renderer.apply(this, arguments);
        $(td).css({'font-weight': 'bold'});
    };

    var $container, $parent, $window, availableWidth, availableHeight;
    var calculateSize = function () {
        var offset = $container.offset();
        availableWidth = Math.max($window.width() - 250,600);
        availableHeight = Math.max($window.height() - 250, 400);
    };

    $container = $("#hot"); $parent = $container.parent();
    $window = $(window);
    $window.on('resize', calculateSize);

    /* make the buttons for the sheets */
    var make_buttons = function(sheetnames, cb) {
        var $buttons = $('#buttons');
        $buttons.html("");
        sheetnames.forEach(function(s,idx) {
            var button= $('<button/>').attr({ type:'button', name:'btn' +idx, text:s });
            button.append('<h3>' + s + '</h3>');
            button.click(function() { cb(idx); });
            $buttons.append(button);
            $buttons.append('<br/>');
        });
    };

    var _onsheet = function(json, cols, sheetnames, select_sheet_cb) {
        $('#footnote').hide();
        $(_target).hide();

        make_buttons(sheetnames, select_sheet_cb);
        calculateSize();

        /* add header row for table */
        if(!json) json = [];
        json.unshift(function(head){var o = {}; for(i=0;i!=head.length;++i) o[head[i]] = head[i]; return o;}(cols));
        calculateSize();
        /* showtime! */
        var columns = cols.map(function(x) {
            //console.log("inside cols: " + x);
            if(x.toLowerCase().includes("date") || x.toLowerCase().includes("_at")){
                return  {data:x, type: 'date',correctFormat: true}
            }
            else{
                return {data:x, type: 'text'};
            }
        });


        $('.cols-list').data("cols-list",columns);

        $("#hot").handsontable({
            data: json,
            startRows: 5,
            startCols: 3,
            fixedRowsTop: 1,
            stretchH: 'all',
            rowHeaders: true,
            columns: columns,
            colHeaders: cols.map(function(x,i) { return XLS.utils.encode_col(i); }),
            cells: function (r,c,p) {
                if(r === 0) this.renderer = boldRenderer;
            },
            width: function () { return availableWidth; },
            height: function () { return availableHeight; },
            stretchH: 'all',
            afterGetColHeader: function (col, TH) {
                if(col < 0){
                    return true;
                }
                //var instance = this,
                //    menu = buildMenu(columns[col].type),
                //    button = buildButton();

                //addButtonMenuEvent(button, menu);

                //Handsontable.Dom.addEvent(menu, 'click', function (event) {
                //    if (event.target.nodeName == 'LI') {
                //        setColumnType(col, event.target.data['colType'], instance);
                //    }
                //});
                //TH.firstChild.appendChild(button);
                //TH.style['white-space'] = 'normal';
            },
            cells: function (row, col, prop) {
                var cellProperties;

                if (row === 0) {
                    cellProperties = {
                        type: 'text' // force text type for first row
                    };

                    return cellProperties;
                }
            },
            afterChange: function(changes, source) {
                console.log("just changed" +changes);
                if(Array.isArray(changes) === true && changes[0][0] == 0){
                    console.log("in header row");
                    var fieldNewName = changes[0][3];
                    var theLabel = $(".field-label." + fieldNewName);
                    if(fieldNewName.includes("customer_")){
                        console.log("trying to change the class");
                        $('.customer_field').addClass("label-success");
                        $('.customer_field').removeClass("label-warning");
                        $($('.customer_field').children()[0]).addClass("fa-check-square-o");
                        $($('.customer_field').children()[0]).removeClass("fa-square-o");
                    }
                    if(theLabel.size() > 0){
                        console.log("trying to change the class");
                        theLabel.addClass("label-success");
                        theLabel.removeClass("label-warning");
                        $(theLabel.children()[0]).addClass("fa-check-square-o");
                        $(theLabel.children()[0]).removeClass("fa-square-o");
                    }
                    else{
                        console.log("not found");
                    }
                }

            }
        });

        $('.cols-list').data('cols-list').forEach(function(obj,i){
            console.log("in cols: "+ obj + "i: " + i);
            if(obj.type === 'date'){
                $('.date-formatter').fadeIn("slow");
                $('.date-format-list').append('<li>'+ json[1][obj.data] +'<span></span></li>');
            }
        })

    };

    function addButtonMenuEvent(button, menu) {
        Handsontable.Dom.addEvent(button, 'click', function (event) {
            var changeTypeMenu, position, removeMenu;

            document.body.appendChild(menu);

            event.preventDefault();
            event.stopImmediatePropagation();

            changeTypeMenu = document.querySelectorAll('.changeTypeMenu');

            for (var i = 0, len = changeTypeMenu.length; i < len; i++) {
                changeTypeMenu[i].style.display = 'none';
            }
            menu.style.display = 'block';
            position = button.getBoundingClientRect();

            menu.style.top = (position.top + (window.scrollY || window.pageYOffset)) + 2 + 'px';
            menu.style.left = (position.left) + 'px';

            removeMenu = function (event) {
                if (event.target.nodeName == 'LI' && event.target.parentNode.className.indexOf('changeTypeMenu') !== -1) {
                    if (menu.parentNode) {
                        menu.parentNode.removeChild(menu);
                    }
                }
            };
            Handsontable.Dom.removeEvent(document, 'click', removeMenu);
            Handsontable.Dom.addEvent(document, 'click', removeMenu);
        });
    }

    function buildMenu(activeCellType){
        var
            menu = document.createElement('UL'),
            types = ['text', 'numeric', 'date'],
            item;

        menu.className = 'changeTypeMenu';

        for (var i = 0, len = types.length; i< len; i++) {
            item = document.createElement('LI');
            if('innerText' in item) {
                item.innerText = types[i];
            } else {
                item.textContent = types[i];
            }

            item.data = {'colType': types[i]};

            if (activeCellType == types[i]) {
                item.className = 'active';
            }
            menu.appendChild(item);
        }

        return menu;
    }

    function buildButton() {
        var button = document.createElement('BUTTON');

        button.innerHTML = '\u25BC';
        button.className = 'changeType';

        return button;
    }

    function setColumnType(i, type, instance) {
        columns[i].type = type;
        instance.updateSettings({columns: columns});
        instance.validateCells(function() {
            instance.render();
        });
    }


    /** Drop it like it's hot **/
    DropSheet({
        drop: _target,
        on: {
            workstart: _workstart,
            workend: _workend,
            sheet: _onsheet,
            foo: 'bar'
        },
        errors: {
            badfile: _badfile,
            pending: _pending,
            failed: _failed,
            large: _large,
            foo: 'bar'
        }
    });
});