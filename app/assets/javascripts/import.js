
var $ = window.jQuery;

$(function() {
  var console = window.console,
    moment = window.moment,
    status_poll_url = window.status_poll_url;

  // DATE FORMATTER
  $('#date-formatter-select').change(function() {
    $('.date-formatter').removeClass("alert alert-danger");
    var dateFormat = $(this).val();
    $("#import_mapping").val(dateFormat);
    $('.date-format-list li').each(function(i,obj){
      $(obj).show();
      console.log("format: "+dateFormat);
      console.log("text: "+$(obj).text());
      $(obj).children("span").text(" > "+ moment($(obj).text(), dateFormat).format());

      //now that we put it in the form, lets send an update so this persists..
      $(".bhv-submit").val("Process Update");
      $(".bhv-submit").trigger('click.rails');
      $(".bhv-submit").val("Process");
    });

  });


  // Results
  (function poll(){
    setTimeout(function(){
      $.ajax({
        url: status_poll_url,
        success: function(data){
          if(data.record_count > 0 && data.record_count === (data.success_count+data.error_count)){
            console.log(data);
            if(data.record_count > 0){
              $(".well.processing").show();
            }
            $(".totals").text(data.record_count);
            $(".label-success.results").text(data.success_count);
            $(".label-danger.results").text(data.error_count);
            $("h2.processing").fadeOut();
            $("h2.completed").fadeIn();
            data.full_errors.forEach(function(obj){
              console.log(obj);
              $("ol").append('<li>' + obj + '</li>');
            });
          }
          else{
            if(data.record_count > 0){
              $(".well.processing").show();
            }
            $(".totals").text(data.record_count);
            $(".label-success.results").text(data.success_count);
            $(".label-error.results").text(data.error_count);
            console.log(data);
            console.log("still polling...");
            poll();
          }
        }, dataType: "json"});
    }, 4000);
  })();
});
