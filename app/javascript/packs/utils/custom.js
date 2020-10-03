console.log("custom js file loaded")

// ContentContainer Scripts in body tag
$(".contentContainer").css("min-height", $(window).height());

// Alert Timer Script
window.setTimeout(function () {
  $(".notify-timer").fadeTo(500, 0).slideUp(500, function () {
    $(this).remove();
  });
}, 5000);

// Request Header X-CSRF-Token
$(function () {
  $('#loader').hide()
  $(document).ajaxStart(function () {
    $('#loader').show();
  })
  $(document).ajaxError(function () {
    alert("Something went wrong...")
    $('#loader').hide();
  })
  $(document).ajaxStop(function () {
    $('#loader').hide();
  });
  $.ajaxSetup({
    beforeSend: function (xhr) {
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
    }
  });
});

//******************************************
// Need to scroll to top/down of the page
//******************************************
// Select all links with hashes
$('a[href*="#"]')
// Remove links that don't actually link to anything
.not('[href="#"]')
.not('[href="#0"]')
.click(function (event) {
  // On-page links
  if (
    location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') &&
    location.hostname == this.hostname
  ) {
    // Figure out element to scroll to
    var target = $(this.hash);
    target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
    // Does a scroll target exist?
    if (target.length) {
      // Only prevent default if animation is actually gonna happen
      event.preventDefault();
      $('html, body').animate({
        scrollTop: target.offset().top
      }, 1000, function () {
        // Callback after animation
        // Must change focus!
        var $target = $(target);
        $target.focus();
        if ($target.is(":focus")) { // Checking if the target was focused
          return false;
        } else {
          $target.attr('tabindex', '-1'); // Adding tabindex for elements not focusable
          $target.focus(); // Set focus again
        };
      });
    }
  }
});

//******************************
// BOTTOM SCROLL TOP BUTTON
//******************************
$(document).ready(function () {
  // declare variable
  var scrollTop = $(".scrolltop");
  //Smooth Scroll to top button + font awesome
  $(window).scroll(function () {
    if ($(this).scrollTop() > 300) {
      $('.scrolltop:hidden').stop(true, true).fadeIn();
    } else {
      $('.scrolltop').stop(true, true).fadeOut();
    }
  });
  //Click event to scroll to top
  $(scrollTop).click(function () {
    $('html, body').animate({
      scrollTop: 0
    }, 800);
    return false;
  }); // click() scroll top EMD
});