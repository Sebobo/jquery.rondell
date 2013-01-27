/*!
 * Test suite for jQuery Rondell
 */

test('Rondell exists', function() {
  var rondell = $('.rondell-container');

  // Test existance of rondell
  equal(rondell.length, 1, 'Rondell element should exist');

  ok(rondell.hasClass('rondell-instance-1'), 'Rondell should have the class with the correct id');
});

asyncTest('Lightbox', function() {
  var rondell = $('.rondell-container');
  var api = rondell.data('api');

  // Check if lightbox is created and shown by calling the api
  api.showLightbox();

  lightbox = $('.rondell-lightbox');

  equal(lightbox.length, 1, 'Lightbox element should exist');
  ok(lightbox.is(':visible'), 'Lightbox should be visible');

  // Try closing the lightbox by clicking the overlay
  setTimeout(function() {
    lightbox.find('.rondell-lightbox-overlay').trigger('click');
    ok(lightbox.not(':visible'), 'Lightbox should now be hidden');

    // Resume testrunner
    start();
  }, 200);
});
