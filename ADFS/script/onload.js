// Copyright (c) Microsoft Corporation.  All rights reserved.

// This file contains several workarounds on inconsistent browser behaviors that administrators may customize.
"use strict";

// iPhone email friendly keyboard does not include "\" key, use regular keyboard instead.
// Note change input type does not work on all versions of all browsers.
if (navigator.userAgent.match(/iPhone/i) != null) {
    var emails = document.querySelectorAll("input[type='email']");
    if (emails) {
        for (var i = 0; i < emails.length; i++) {
            emails[i].type = 'text';
        }
    }
}

// In the CSS file we set the ms-viewport to be consistent with the device dimensions, 
// which is necessary for correct functionality of immersive IE. 
// However, for Windows 8 phone we need to reset the ms-viewport's dimension to its original
// values (auto), otherwise the viewport dimensions will be wrong for Windows 8 phone.
// Windows 8 phone has agent string 'IEMobile 10.0'
if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
    var msViewportStyle = document.createElement("style");
    msViewportStyle.appendChild(
        document.createTextNode(
            "@-ms-viewport{width:auto!important}"
        )
    );
    msViewportStyle.appendChild(
        document.createTextNode(
            "@-ms-viewport{height:auto!important}"
        )
    );
    document.getElementsByTagName("head")[0].appendChild(msViewportStyle);
}

// If the innerWidth is defined, use it as the viewport width.
if (window.innerWidth && window.outerWidth && window.innerWidth !== window.outerWidth) {
    var viewport = document.querySelector("meta[name=viewport]");
    viewport.setAttribute('content', 'width=' + window.innerWidth + ', initial-scale=1.0, user-scalable=1');
}

// Gets the current style of a specific property for a specific element.
function getStyle(element, styleProp) {
    var propStyle = null;

    if (element && element.currentStyle) {
        propStyle = element.currentStyle[styleProp];
    }
    else if (element && window.getComputedStyle) {
        propStyle = document.defaultView.getComputedStyle(element, null).getPropertyValue(styleProp);
    }

    return propStyle;
}

// The script below is used for downloading the illustration image 
// only when the branding is displaying. This script work together
// with the code in PageBase.cs that sets the html inline style
// containing the class 'illustrationClass' with the background image.
var computeLoadIllustration = function () {
    var branding = document.getElementById("branding");
    var brandingDisplay = getStyle(branding, "display");
    var brandingWrapperDisplay = getStyle(document.getElementById("brandingWrapper"), "display");

    if (brandingDisplay && brandingDisplay !== "none" &&
        brandingWrapperDisplay && brandingWrapperDisplay !== "none") {
        var newClass = "illustrationClass";

        if (branding.classList && branding.classList.add) {
            branding.classList.add(newClass);
        } else if (branding.className !== undefined) {
            branding.className += " " + newClass;
        }
        if (window.removeEventListener) {
            window.removeEventListener('load', computeLoadIllustration, false);
            window.removeEventListener('resize', computeLoadIllustration, false);
        }
        else if (window.detachEvent) {
            window.detachEvent('onload', computeLoadIllustration);
            window.detachEvent('onresize', computeLoadIllustration);
        }
    }
};

if (window.addEventListener) {
    window.addEventListener('resize', computeLoadIllustration, false);
    window.addEventListener('load', computeLoadIllustration, false);
}
else if (window.attachEvent) {
    window.attachEvent('onresize', computeLoadIllustration);
    window.attachEvent('onload', computeLoadIllustration);
}

// Function to change illustration image. Usage example below.
function SetIllustrationImage(imageUri) {
    var illustrationImageClass = '.illustrationClass {background-image:url(' + imageUri + ');}';

    var css = document.createElement('style');
    css.type = 'text/css';

    if (css.styleSheet) css.styleSheet.cssText = illustrationImageClass;
    else css.appendChild(document.createTextNode(illustrationImageClass));

    document.getElementsByTagName("head")[0].appendChild(css);
}

// Added below login function the allow no domain input as username
if (typeof Login != 'undefined'){
    Login.submitLoginRequest = function () { 
    var u = new InputUtil();
    var e = new LoginErrors();
    var userName = document.getElementById(Login.userNameInput);
    var password = document.getElementById(Login.passwordInput);
    if (userName.value && !userName.value.match('[@\\\\]')) 
    {
        var userNameValue = 'REPLACENETBIOS\\' + userName.value;
        document.forms['loginForm'].UserName.value = userNameValue;
    }

    if (!userName.value) {
       u.setError(userName, e.userNameFormatError);
       return false;
    }


    if (!password.value) 
    {
        u.setError(password, e.passwordEmpty);
        return false;
    }
    document.forms['loginForm'].submit();
    return false;
};
}

// Added below login function the allow no domain input as username for passwordpage
if (typeof UpdatePassword != 'undefined'){
    UpdatePassword.submitPasswordChange = function () { 
    var u = new InputUtil();
    var e = new UpdErrors();
 
    var userName = document.getElementById(UpdatePassword.userNameInput);
    var oldPassword = document.getElementById(UpdatePassword.oldPasswordInput);
    var newPassword = document.getElementById(UpdatePassword.newPasswordInput);
    var confirmNewPassword = document.getElementById(UpdatePassword.confirmNewPasswordInput);
 
    if (userName.value && !userName.value.match('[@\\\\]')) 
    {
        var userNameValue = 'REPLACENETBIOS\\' + userName.value;
        document.forms['updatePasswordForm'].UserName.value = userNameValue;
    }
 
    if (!userName.value) {
       u.setError(userName, e.userNameFormatError);
       return false;
    }
 
    if (!oldPassword.value) {
        u.setError(oldPassword, e.oldPasswordEmpty);
        return false;
    }
 
    if (oldPassword.value.length > maxPasswordLength) {
        u.setError(oldPassword, e.oldPasswordTooLong);
        return false;
    }
 
    if (!newPassword.value) {
        u.setError(newPassword, e.newPasswordEmpty);
        return false;
    }
 
    if (!confirmNewPassword.value) {
        u.setError(confirmNewPassword, e.confirmNewPasswordEmpty);
        return false;
    }
 
    if (newPassword.value.length > maxPasswordLength) {
        u.setError(newPassword, e.newPasswordTooLong);
        return false;
    }
 
    if (newPassword.value !== confirmNewPassword.value) {
        u.setError(confirmNewPassword, e.mismatchError);
        return false;
    }
 
    return true;
};
}


// Check whether the userNameInput element is present on this page.
var userNameInput = document.getElementById('userNameInput');
if (userNameInput)
{
	// userNameInput element is present, modify its properties.
	userNameInput.placeholder = 'Username';
}

// Get DOM elements and save as objects
var loginMessage = document.getElementById('loginMessage'),
    loginArea = document.getElementById('loginArea'),
    loginForm = document.getElementById('loginForm'),
    userNameInput = document.getElementById('userNameInput'),
    helpContent,
    usernameLink,
    passwordResetLink,
    errorText = document.getElementById("errorText"),
    introArea = document.getElementById("introduction"),
    authArea = document.getElementById("authArea");
 
var showingHelper = false,
    showingLoginform = false;
 
// CREATE CONTENT FUNCTIONS
 
function createHelpersForLoginForm() {
  //Create the hyperlink to the help form
  passwordResetLink = document.createElement('a');
  var linkText = "Need help?";
  passwordResetLink.appendChild(document.createTextNode(linkText));
  passwordResetLink.title = linkText;
  passwordResetLink.href = "#";
  passwordResetLink.onclick = toggleHelpContent;
 
  loginArea.appendChild(passwordResetLink);
}
 
function createHelpContent() {
  if (!authArea) {
    return;
  }
  helpContent = document.createElement("div");
  helpContent.style.display = 'none';
 
  helpContent.innerHTML = '\
    <br><br>\
    <h2><strong>What is my username?</strong></h2>\
	<p>Your username is your mail address at REPLACEDOMAIN.</p><p>Example: firstname.lastname@REPLACEDOMAIN</p>\<br>\
    <h2><strong>What is my password?</strong></h2>\
    <p>This is a secret chosen by you. It would not be a secret if we told you.</p><p>If you forgot your password, you can reset it <a href="https://passwordreset.microsoftonline.com/?whr=REPLACEDOMAIN" target="_blank">here</a>.</p>\
	<p>If you would like to change your password, you can change it <a href="https://adfs.REPLACEDOMAIN/adfs/portal/updatepassword/" target="_blank">here</a>.</p>\
    <br>\
    <h2><strong>Support</strong></h2>\
    <p>If you have any issues or questions, please contact our helpdesk at <a href="mailto:info@REPLACEDOMAIN">info@REPLACEDOMAIN</a>.<br><br><br></p>\
    ';
 
  // Link for close help
  var closeHelpContentLink = document.createElement('span');
  closeHelpContentLink.innerHTML = "Back to the login form";
  closeHelpContentLink.className = "submit";
  closeHelpContentLink.onclick = toggleHelpContent;
 
  // Duplicate it to have one before the content as well.
  // Uncomment these lines if the help  content grows.
  // var closeHelpContentLinkUpper = closeHelpContentLink.cloneNode(true);
  // closeHelpContentLinkUpper.onclick = toggleHelpContent;
  // helpContent.insertBefore(closeHelpContentLinkUpper, helpContent.firstChild);
 
  helpContent.appendChild(closeHelpContentLink);
 
  authArea.appendChild(helpContent);
}
 
function updateUI() {
  // Check for DOM errors
  if (!loginForm || !helpContent) {
    return;
  }
 
  if (showingHelper) {
    openHelpContent();
  } else {
    closeHelpContent();
  }
}
 
function toggleHelpContent() {
  showingHelper = !showingHelper;
 
  updateUI();
}
 
function openHelpContent() {
    helpContent.style.display="block";
    loginArea.style.display="none"
}
 
function closeHelpContent() {
    helpContent.style.display="none";
    loginArea.style.display="block"
}
 
// Create DOM elements 
createHelpersForLoginForm();
createHelpContent();
updateUI();