var datasets = {};
var dragOver = function(e) { e.preventDefault(); };

var dropData = function(e) {
    e.preventDefault();
    var data = e.dataTransfer.getData("text");
    e.target.setAttribute('src', data);
    var dataName = data.substring(data.indexOf('df')+2, data.indexOf('png')-1);
    Shiny.onInputChange('dfName', dataName);
};

