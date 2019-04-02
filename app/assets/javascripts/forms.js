$(function () {
  var DEFAULT_PRIVACY_TEXT = "I have read and agreed to the";
  var DEFAULT_EMAIL_TEXT = "Email (required)";
  var DEFAULT_SUBSCRIPTION_TEXT = "It’s okay to send me email every once in a while.";

  $(document).ready(function() {
    $("#privacy_text").text(DEFAULT_PRIVACY_TEXT);
    $("#agreement_text").text(DEFAULT_SUBSCRIPTION_TEXT);
    $("#email_text label").text(DEFAULT_EMAIL_TEXT);
  });
  $("#under_age").change(function() {
    if ($("#under_age").is(':checked')) {
      $("#privacy_text").text("I confirm I am the parent/guardian and give permission for my child to register by providing my email address as the main contact address. Both I and my child understand and agree to the");
      $("#agreement_text").text("If you agree, we will periodically send email promoting new research-related projects or other information relating to our research. We will not use your contact information for commercial purposes.");
      $("#anonymous_text").text("Don't use your real name");
      $("#email_text label").text("Parent/Guardian's Email (required)");
    } else {
      $("#privacy_text").text(DEFAULT_PRIVACY_TEXT);
      $("#agreement_text").text(DEFAULT_SUBSCRIPTION_TEXT);
      $("#anonymous_text").text("");
      $("#email_text label").text(DEFAULT_EMAIL_TEXT);
    }
    });
  });
